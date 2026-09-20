///|
fn grapheme_parse_hex(text : StringView) -> Int {
  let mut value = 0
  for ch in text {
    let digit = if ch >= '0' && ch <= '9' {
      ch.to_int() - '0'.to_int()
    } else if ch >= 'A' && ch <= 'F' {
      ch.to_int() - 'A'.to_int() + 10
    } else {
      ch.to_int() - 'a'.to_int() + 10
    }
    value = value * 16 + digit
  }
  value
}

///|
fn grapheme_parse_scalars(text : StringView) -> Array[Int] {
  let values : Array[Int] = []
  if text.length() > 0 {
    for token in text.split(" ") {
      if token.length() > 0 {
        values.push(grapheme_parse_hex(token))
      }
    }
  }
  values
}

///|
fn grapheme_parse_indexes(text : StringView) -> Array[Int] {
  let values : Array[Int] = []
  for token in text.split(" ") {
    if token.length() > 0 {
      values.push(grapheme_parse_hex(token))
    }
  }
  values
}

///|
fn utf8_width(cp : Int) -> Int {
  if cp <= 0x7F {
    1
  } else if cp <= 0x7FF {
    2
  } else if cp <= 0xFFFF {
    3
  } else {
    4
  }
}

///|
fn expected_ranges(
  scalars : Array[Int],
  breaks : Array[Int],
) -> Array[(Int, Int)] {
  let offsets = [0]
  let mut offset = 0
  for cp in scalars {
    offset += utf8_width(cp)
    offsets.push(offset)
  }
  let ranges : Array[(Int, Int)] = []
  for index = 0; index + 1 < breaks.length(); index = index + 1 {
    ranges.push((offsets[breaks[index]], offsets[breaks[index + 1]]))
  }
  ranges
}

///|
fn grapheme_code_points(scalars : Array[Int]) -> String {
  "[" + scalars.map(value => "U+" + value.to_string()).join(", ") + "]"
}

///|
test "Unicode 16.0 GraphemeBreakTest vectors" {
  let mut passed = 0
  let failures : Array[String] = []
  for encoded in grapheme_cases {
    let fields = encoded.split("|").to_array()
    let source_line = fields[0].to_string()
    let scalars = grapheme_parse_scalars(fields[1])
    let breaks = grapheme_parse_indexes(fields[2])
    let input = String::from_array(scalars.map(value => value.unsafe_to_char()))
    let expected = expected_ranges(scalars, breaks)
    let actual = @grapheme.grapheme_boundaries(input).to_array()
    if actual != expected {
      failures.push(
        "GraphemeBreakTest.txt:" +
        source_line +
        " target=native API=grapheme_boundaries input=" +
        grapheme_code_points(scalars) +
        " expected_boundaries=" +
        expected.to_string() +
        " actual_boundaries=" +
        actual.to_string() +
        " source=" +
        fields[3].to_string(),
      )
    } else {
      passed += 1
    }
  }
  if failures.length() > 0 {
    abort(
      "GraphemeBreakTest.txt conformance: total=" +
      grapheme_cases.length().to_string() +
      " passed=" +
      passed.to_string() +
      " failed=" +
      failures.length().to_string() +
      " skipped=0\n" +
      failures.join("\n"),
    )
  }
}
