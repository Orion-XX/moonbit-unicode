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
