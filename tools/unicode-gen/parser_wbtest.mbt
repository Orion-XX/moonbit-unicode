///|
test "property ranges and source locations" {
  let result = parse_property_file(
    "fixture/GraphemeBreakProperty.txt", "0041..005A ; Upper\n0061 ; Lower\n",
  )
  match result {
    Ok(records) => {
      assert_eq(records.length(), 2)
      assert_eq(records[0].range.start, 0x41)
      assert_eq(records[0].source.line, 1)
    }
    Err(e) => fail(e.to_string())
  }
}

///|
test "malformed scalar includes filename and line" {
  match parse_property_file("fixture/bad.txt", "110000 ; Bad\n") {
    Ok(_) => fail("expected malformed scalar")
    Err(e) => {
      assert_true(e.to_string().contains("fixture/bad.txt:1"))
      assert_true(e.to_string().contains("malformed scalar"))
    }
  }
}

///|
test "overlap and missing fields report their source line" {
  match
    parse_property_file(
      "fixture/overlap.txt", "0041..0043 ; A\n0043..0044 ; B\n",
    ) {
    Ok(_) => fail("expected overlap")
    Err(e) => assert_true(e.to_string().contains("fixture/overlap.txt:2"))
  }
  match parse_unicode_data("fixture/missing.txt", "0041;A;Ll\n") {
    Ok(_) => fail("expected missing field")
    Err(e) => assert_true(e.to_string().contains("fixture/missing.txt:1"))
  }
}

///|
test "canonical decomposition and ccc are typed separately" {
  let input = "00C0;LATIN CAPITAL LETTER A WITH GRAVE;Lu;0;L;0041 0300;;;;N;;;;00E0;\n00A0;NO-BREAK SPACE;Zs;0;CS;<noBreak> 0020;;;;N;;;;;\n"
  match parse_unicode_data("fixture/UnicodeData.txt", input) {
    Ok((decomp, ccc)) => {
      assert_eq(decomp.length(), 2)
      assert_true(decomp[0].canonical)
      assert_false(decomp[1].canonical)
      assert_eq(decomp[0].mapping, [0x41, 0x300])
      assert_eq(ccc.length(), 2)
    }
    Err(e) => fail(e.to_string())
  }
}

///|
test "composition exclusions and conformance vectors" {
  match parse_exclusions("fixture/CompositionExclusions.txt", "0340\n0341\n") {
    Ok(values) => assert_eq(values.length(), 2)
    Err(e) => fail(e.to_string())
  }
  match
    parse_conformance_file(
      "fixture/NormalizationTest.txt", "0041 030A; 00C5; 0041 030A; 0041 030A; 00C5\n",
    ) {
    Ok(values) => {
      assert_eq(values.length(), 1)
      assert_eq(values[0].columns.length(), 5)
      assert_eq(values[0].source.line, 1)
    }
    Err(e) => fail(e.to_string())
  }
}

///|
test "conflicting property records are rejected" {
  match parse_property_file("fixture/conflict.txt", "0041 ; A\n0041 ; B\n") {
    Ok(_) => fail("expected conflicting duplicate")
    Err(e) => assert_true(e.to_string().contains("fixture/conflict.txt:2"))
  }
}
