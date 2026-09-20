///|
fn find_canonical(cp : Int) -> CanonicalDecomposition? {
  for entry in canonical_decompositions {
    if entry.cp == cp {
      return Some(entry)
    }
  }
  None
}

///|
fn find_compatibility(cp : Int) -> CompatibilityDecomposition? {
  for entry in compatibility_decompositions {
    if entry.cp == cp {
      return Some(entry)
    }
  }
  None
}

///|
fn find_combining_class(cp : Int) -> Int {
  for entry in combining_class_ranges {
    if cp >= entry.start && cp <= entry.end {
      return entry.ccc
    }
  }
  0
}

///|
fn find_composition(starter : Int, combining : Int) -> Int? {
  for entry in composition_pairs {
    if entry.starter == starter && entry.combining == combining {
      return Some(entry.composite)
    }
  }
  None
}

///|
fn find_grapheme_break_property(cp : Int) -> GraphemeBreakProperty {
  for entry in grapheme_break_ranges {
    if cp >= entry.start && cp <= entry.end {
      return entry.property
    }
  }
  Other
}

///|
fn is_extended_pictographic(cp : Int) -> Bool {
  for entry in extended_pictographic_ranges {
    if cp >= entry.start && cp <= entry.end {
      return true
    }
  }
  false
}

///|
test "canonical and compatibility mappings remain distinct" {
  match find_canonical(0x00C0) {
    Some(entry) => assert_eq(entry.mapping, [0x41, 0x300])
    None => fail("missing canonical mapping")
  }
  match find_compatibility(0x00A0) {
    Some(entry) => assert_eq(entry.mapping, [0x20])
    None => fail("missing compatibility mapping")
  }
  assert_true(find_canonical(0x00A0) is None)
  assert_true(find_compatibility(0x00C0) is None)
}

///|
test "algorithmic Hangul syllables are absent from per-syllable tables" {
  assert_true(find_canonical(0xAC00) is None)
  assert_true(find_canonical(0xD7A3) is None)
}

///|
test "CCC and composition data are generated separately" {
  assert_eq(find_combining_class(0x0300), 230)
  assert_eq(find_combining_class(0x0041), 0)
  match find_composition(0x0041, 0x0300) {
    Some(composite) => assert_eq(composite, 0x00C0)
    None => fail("missing canonical composition pair")
  }
}

///|
test "composition exclusions are retained" {
  assert_true(composition_exclusions.contains(0x0958))
  // U+0958 has a canonical two-scalar mapping but is excluded from NFC
  // composition; the pair must therefore not be emitted.
  assert_true(find_composition(0x0915, 0x093C) is None)
}

///|
test "generated grapheme ranges cover every UAX 29 state property" {
  assert_true(find_grapheme_break_property(0x0000) is Control)
  assert_true(find_grapheme_break_property(0x000D) is CR)
  assert_true(find_grapheme_break_property(0x000A) is LF)
  assert_true(find_grapheme_break_property(0x0300) is Extend)
  assert_true(find_grapheme_break_property(0x200D) is ZWJ)
  assert_true(find_grapheme_break_property(0x0600) is Prepend)
  assert_true(find_grapheme_break_property(0x0903) is SpacingMark)
  assert_true(find_grapheme_break_property(0x1100) is L)
  assert_true(find_grapheme_break_property(0x1160) is V)
  assert_true(find_grapheme_break_property(0x11A8) is T)
  assert_true(find_grapheme_break_property(0xAC00) is LV)
  assert_true(find_grapheme_break_property(0xAC01) is LVT)
  assert_true(find_grapheme_break_property(0x1F1E6) is RegionalIndicator)
  assert_true(find_grapheme_break_property(0x0041) is Other)
}

///|
test "generated Extended_Pictographic ranges remain separate from grapheme breaks" {
  assert_true(is_extended_pictographic(0x1F469))
  assert_true(is_extended_pictographic(0x2764))
  assert_false(is_extended_pictographic(0x0041))
}
