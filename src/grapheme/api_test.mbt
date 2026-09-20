///|
test "empty and ASCII boundaries" {
  assert_eq(grapheme_boundaries("").to_array(), [])
  assert_eq(grapheme_boundaries("abc").to_array(), [(0, 1), (1, 2), (2, 3)])
}

///|
test "required grapheme rules" {
  assert_eq(grapheme_boundaries("\r\n").to_array(), [(0, 2)])
  assert_eq(grapheme_boundaries("a\u{300}").to_array(), [(0, 3)])
  assert_eq(grapheme_boundaries("\u{600}a\u{903}").to_array(), [(0, 6)])
  assert_eq(grapheme_boundaries("\u{1100}\u{1161}\u{11A8}").to_array(), [(0, 9)])
  assert_eq(grapheme_boundaries("👩‍👩‍👧‍👦").to_array(), [
    (0, 25),
  ])
  assert_eq(grapheme_boundaries("🇦🇧🇨").to_array(), [(0, 8), (8, 12)])
}

///|
test "Indic conjunct GB9c" {
  assert_eq(grapheme_boundaries("\u{915}\u{94D}\u{924}").to_array(), [(0, 9)])
  assert_eq(grapheme_boundaries("\u{915}\u{94D}\u{94D}\u{924}").to_array(), [
    (0, 12),
  ])
  assert_eq(grapheme_boundaries("\u{915}\u{94D}\u{200D}\u{924}").to_array(), [
    (0, 12),
  ])
  assert_eq(grapheme_boundaries("\u{915}\u{924}").to_array(), [(0, 3), (3, 6)])
  assert_eq(grapheme_boundaries("\u{915}\u{94D}a").to_array(), [(0, 6), (6, 7)])
}

///|
test "controls always form separate clusters" {
  assert_eq(grapheme_boundaries("a\n\u{300}b").to_array(), [
    (0, 1),
    (1, 2),
    (2, 4),
    (4, 5),
  ])
}

///|
test "ranges reconstruct UTF-8 bytes and never split scalars" {
  let input = "A中😀e\u{301}"
  let bytes = @utf8.encode(input)
  let ranges = grapheme_boundaries(input).to_array()
  let mut previous_end = 0
  let reconstructed : Array[Byte] = []
  for range in ranges {
    let start = range.0
    let end = range.1
    assert_eq(start, previous_end)
    assert_true(start < end)
    bytes[start:end].iter().each(byte => reconstructed.push(byte))
    previous_end = end
  }
  assert_eq(previous_end, bytes.length())
  assert_eq(reconstructed, bytes.to_array())
}
