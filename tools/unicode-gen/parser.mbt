///|
/// A source position is retained on every parsed record and diagnostic.
pub struct Source {
  filename : String
  line : Int
}

///|
pub struct CodePointRange {
  start : Int
  end : Int
}

///|
pub struct PropertyRecord {
  range : CodePointRange
  property : String
  source : Source
}

///|
pub struct DecompositionRecord {
  code_point : Int
  mapping : Array[Int]
  canonical : Bool
  source : Source
}

///|
pub struct CccRecord {
  code_point : Int
  ccc : Int
  source : Source
}

///|
pub struct ConformanceVector {
  columns : Array[Array[Int]]
  source : Source
}

///|
pub enum ParseErrorKind {
  MalformedScalar
  MalformedRecord
  OverlappingRange
  ConflictingDuplicate
  MissingField
  InvalidVector
}

///|
pub struct ParseError {
  kind : ParseErrorKind
  source : Source
  detail : String
}

///|
fn error(
  kind : ParseErrorKind,
  filename : String,
  line : Int,
  detail : String,
) -> ParseError {
  { kind, source: { filename, line }, detail }
}

///|
pub fn ParseError::to_string(self : ParseError) -> String {
  let kind = match self.kind {
    MalformedScalar => "malformed scalar"
    MalformedRecord => "malformed record"
    OverlappingRange => "overlapping range"
    ConflictingDuplicate => "conflicting duplicate"
    MissingField => "missing field"
    InvalidVector => "invalid conformance vector"
  }
  self.source.filename +
  ":" +
  self.source.line.to_string() +
  ": " +
  kind +
  ": " +
  self.detail
}

///|
fn hex_digit(c : Char) -> Int? {
  if c >= '0' && c <= '9' {
    Some(c.to_int() - '0'.to_int())
  } else if c >= 'A' && c <= 'F' {
    Some(c.to_int() - 'A'.to_int() + 10)
  } else if c >= 'a' && c <= 'f' {
    Some(c.to_int() - 'a'.to_int() + 10)
  } else {
    None
  }
}

///|
fn parse_hex(
  text : StringView,
  filename : String,
  line : Int,
) -> Result[Int, ParseError] {
  if text.length() == 0 {
    return Err(error(MalformedScalar, filename, line, "empty code point"))
  }
  let mut value = 0
  for c in text {
    match hex_digit(c) {
      Some(d) => value = value * 16 + d
      None =>
        return Err(
          error(
            MalformedScalar,
            filename,
            line,
            "invalid hexadecimal code point",
          ),
        )
    }
  }
  if value > 0x10FFFF || (value >= 0xD800 && value <= 0xDFFF) {
    return Err(
      error(
        MalformedScalar,
        filename,
        line,
        "code point is not a Unicode scalar",
      ),
    )
  }
  Ok(value)
}

///|
fn parse_range(
  text : StringView,
  filename : String,
  line : Int,
) -> Result[CodePointRange, ParseError] {
  let pieces = text.split("..").to_array()
  match pieces {
    [one] => parse_hex(one, filename, line).map(fn(x) { { start: x, end: x } })
    [lo, hi] => {
      let start = match parse_hex(lo, filename, line) {
        Ok(x) => x
        Err(e) => return Err(e)
      }
      let end = match parse_hex(hi, filename, line) {
        Ok(x) => x
        Err(e) => return Err(e)
      }
      if start > end {
        Err(error(MalformedRecord, filename, line, "range start exceeds end"))
      } else {
        Ok({ start, end })
      }
    }
    _ => Err(error(MalformedRecord, filename, line, "invalid code point range"))
  }
}

///|
fn data_part(line : String) -> StringView {
  match line.split("#").to_array() {
    [head, ..] => head.trim_space()
    _ => "" // split always yields at least one part
  }
}

///|
fn check_overlap(
  ranges : Array[CodePointRange],
  candidate : CodePointRange,
  source : Source,
) -> ParseError? {
  for old in ranges {
    if candidate.start <= old.end && old.start <= candidate.end {
      return Some(
        error(
          OverlappingRange,
          source.filename,
          source.line,
          "range overlaps an earlier record",
        ),
      )
    }
  }
  None
}

///|
/// Parse UCD semicolon/property files such as GraphemeBreakProperty.txt and emoji-data.txt.
pub fn parse_property_file(
  filename : String,
  input : String,
) -> Result[Array[PropertyRecord], ParseError] {
  let records : Array[PropertyRecord] = []
  let ranges : Array[CodePointRange] = []
  let mut line_no = 0
  for raw in input.split("\n") {
    line_no += 1
    let line = data_part(raw.to_string())
    if line == "" {
      continue
    }
    let fields = line.split(";").to_array()
    if fields.length() != 2 {
      return Err(
        error(MalformedRecord, filename, line_no, "expected range ; property"),
      )
    }
    let range = match parse_range(fields[0].trim_space(), filename, line_no) {
      Ok(x) => x
      Err(e) => return Err(e)
    }
    let property = fields[1].trim_space().to_string()
    if property == "" {
      return Err(error(MissingField, filename, line_no, "property is empty"))
    }
    for i = 0; i < records.length(); i = i + 1 {
      let old = records[i]
      if range.start <= old.range.end && old.range.start <= range.end {
        let kind = if range.start == old.range.start &&
          range.end == old.range.end &&
          property != old.property {
          ConflictingDuplicate
        } else {
          OverlappingRange
        }
        return Err(
          error(kind, filename, line_no, "range overlaps an earlier record"),
        )
      }
    }
    ranges.push(range)
    records.push({ range, property, source: { filename, line: line_no } })
  }
  Ok(records)
}

///|
/// Parse UnicodeData.txt fields, retaining canonical decomposition and CCC.
pub fn parse_unicode_data(
  filename : String,
  input : String,
) -> Result[(Array[DecompositionRecord], Array[CccRecord]), ParseError] {
  let decompositions : Array[DecompositionRecord] = []
  let cccs : Array[CccRecord] = []
  let mut line_no = 0
  for raw in input.split("\n") {
    line_no += 1
    let line = data_part(raw.to_string())
    if line == "" {
      continue
    }
    let fields = line.split(";").to_array()
    if fields.length() < 6 {
      return Err(
        error(
          MissingField,
          filename,
          line_no,
          "UnicodeData record has fewer than six fields",
        ),
      )
    }
    let cp = match parse_hex(fields[0].trim_space(), filename, line_no) {
      Ok(x) => x
      Err(e) => return Err(e)
    }
    let ccc = match parse_decimal(fields[3].trim_space(), filename, line_no) {
      Ok(x) => x
      Err(e) => return Err(e)
    }
    cccs.push({ code_point: cp, ccc, source: { filename, line: line_no } })
    let decomposition = fields[5].trim_space().to_string()
    if decomposition != "" {
      let parts = decomposition.split(" ").to_array()
      let canonical = !parts[0].contains("<")
      let start = if canonical { 0 } else { 1 }
      if parts.length() <= start {
        return Err(
          error(
            MissingField,
            filename,
            line_no,
            "decomposition mapping is empty",
          ),
        )
      }
      let mapping : Array[Int] = []
      for i = start; i < parts.length(); i = i + 1 {
        match parse_hex(parts[i], filename, line_no) {
          Ok(x) => mapping.push(x)
          Err(e) => return Err(e)
        }
      }
      decompositions.push({
        code_point: cp,
        mapping,
        canonical,
        source: { filename, line: line_no },
      })
    }
  }
  Ok((decompositions, cccs))
}

///|
fn parse_decimal(
  text : StringView,
  filename : String,
  line : Int,
) -> Result[Int, ParseError] {
  if text.length() == 0 {
    return Err(error(MissingField, filename, line, "decimal field is empty"))
  }
  let mut value = 0
  for c in text {
    if c < '0' || c > '9' {
      return Err(
        error(MalformedRecord, filename, line, "invalid decimal field"),
      )
    }
    value = value * 10 + c.to_int() - '0'.to_int()
  }
  Ok(value)
}

///|
/// Parse CompositionExclusions.txt, which is a one-column scalar/range file.
pub fn parse_exclusions(
  filename : String,
  input : String,
) -> Result[Array[CodePointRange], ParseError] {
  let records : Array[CodePointRange] = []
  let mut line_no = 0
  for raw in input.split("\n") {
    line_no += 1
    let line = data_part(raw.to_string())
    if line == "" {
      continue
    }
    let range = match parse_range(line, filename, line_no) {
      Ok(x) => x
      Err(e) => return Err(e)
    }
    match check_overlap(records, range, { filename, line: line_no }) {
      Some(e) => return Err(e)
      None => ()
    }
    records.push(range)
  }
  Ok(records)
}

///|
/// Parse NormalizationTest.txt or GraphemeBreakTest.txt vector rows.
pub fn parse_conformance_file(
  filename : String,
  input : String,
) -> Result[Array[ConformanceVector], ParseError] {
  let vectors : Array[ConformanceVector] = []
  let mut line_no = 0
  for raw in input.split("\n") {
    line_no += 1
    let line = data_part(raw.to_string())
    if line == "" {
      continue
    }
    let columns = line.split(";").to_array()
    if columns.length() < 2 {
      return Err(
        error(
          InvalidVector,
          filename,
          line_no,
          "expected at least two semicolon-separated columns",
        ),
      )
    }
    let parsed : Array[Array[Int]] = []
    for column in columns {
      let scalars : Array[Int] = []
      let text = column.trim_space()
      if text != "" {
        for token in text.split(" ") {
          if token.trim_space() != "" {
            match parse_hex(token.trim_space(), filename, line_no) {
              Ok(x) => scalars.push(x)
              Err(e) => return Err(e)
            }
          }
        }
      }
      parsed.push(scalars)
    }
    vectors.push({ columns: parsed, source: { filename, line: line_no } })
  }
  Ok(vectors)
}
