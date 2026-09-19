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
