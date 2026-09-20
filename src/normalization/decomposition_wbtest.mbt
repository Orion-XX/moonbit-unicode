///|
test "empty and unchanged scalars remain empty or unchanged" {
  assert_eq(decompose_canonical([]), [])
  assert_eq(decompose_canonical([0x41, 0x0378, 0x110000]), [
    0x41, 0x0378, 0x110000,
  ])
}

///|
test "canonical Latin mapping is recursive but not reordered" {
  assert_eq(decompose_canonical([0x00C0]), [0x41, 0x0300])
  // U+1F82 -> U+1F02 + U+0345, then U+1F02 -> U+1F00 + U+0300.
  assert_eq(decompose_canonical([0x1F82]), [0x03B1, 0x0313, 0x0300, 0x0345])
}

///|
test "compatibility mappings are not used" {
  // U+00A0 has only a compatibility mapping to SPACE.
  assert_eq(decompose_canonical([0x00A0]), [0x00A0])
}

///|
test "Hangul LV and LVT use the UAX 15 algorithm" {
  // U+AC00 = U+1100 U+1161 (LV).
  assert_eq(decompose_canonical([0xAC00]), [0x1100, 0x1161])
  // U+AC01 = U+1100 U+1161 U+11A8 (LVT).
  assert_eq(decompose_canonical([0xAC01]), [0x1100, 0x1161, 0x11A8])
  // The final scalar is not a Hangul syllable and remains unchanged.
  assert_eq(decompose_canonical([0xD7A3, 0xD7A4]), [
    0x1112, 0x1175, 0x11C2, 0xD7A4,
  ])
}
