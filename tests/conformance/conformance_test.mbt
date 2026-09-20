///|
fn parse_hex(text : StringView) -> Int {
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
fn parse_column(text : StringView) -> Array[Int] {
  let values : Array[Int] = []
  if text.length() > 0 {
    for token in text.split(" ") {
      if token.length() > 0 {
        values.push(parse_hex(token))
      }
    }
  }
  values
}

///|
fn normalized(values : Array[Int]) -> String {
  String::from_array(values.map(value => value.unsafe_to_char()))
}

///|
fn code_points(values : Array[Int]) -> String {
  "[" + values.map(value => "U+" + value.to_string()).join(", ") + "]"
}

///|
test "Unicode 16.0 NormalizationTest vectors" {
  for encoded in normalization_cases {
    let fields = encoded.split("|").to_array()
    let source_line = fields[0].to_string()
    let columns : Array[Array[Int]] = []
    for index = 1; index < fields.length(); index = index + 1 {
      columns.push(parse_column(fields[index]))
    }
    let values = columns.map(normalized)
    let expected_nfc = values[1]
    let expected_nfd = values[2]
    // Columns 4 and 5 are compatibility forms (NFKC/NFKD) and are retained
    // in the fixture but deliberately excluded from this NFC/NFD task.
    for index = 0; index < 3; index = index + 1 {
      let input = values[index]
      let nfc_actual = @normalization.nfc(input)
      if nfc_actual != expected_nfc {
        abort(
          "NormalizationTest.txt:" +
          source_line +
          " NFC column=" +
          (index + 1).to_string() +
          " input=" +
          code_points(columns[0]) +
          " expected=" +
          code_points(columns[1]) +
          " actual=" +
          code_points(nfc_actual.iter().to_array().map(ch => ch.to_int())),
        )
      }
      let nfd_actual = @normalization.nfd(input)
      if nfd_actual != expected_nfd {
        abort(
          "NormalizationTest.txt:" +
          source_line +
          " NFD column=" +
          (index + 1).to_string() +
          " input=" +
          code_points(columns[0]) +
          " expected=" +
          code_points(columns[2]) +
          " actual=" +
          code_points(nfd_actual.iter().to_array().map(ch => ch.to_int())),
        )
      }
    }
  }
}
