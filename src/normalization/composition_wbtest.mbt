///|
test "composes a canonical Latin pair" {
  assert_eq(compose_canonical([0x0041, 0x0300]), [0x00C0])
}

///|
test "canonical blocking preserves a later pair" {
  // A + grave composes first; the equal-CCC acute is then blocked from A.
  assert_eq(compose_canonical([0x0041, 0x0300, 0x0301]), [0x00C0, 0x0301])
}

///|
test "composition exclusions do not compose" {
  // U+0958 is canonically K+A nukta but excluded from NFC composition.
  assert_eq(compose_canonical([0x0915, 0x093C]), [0x0915, 0x093C])
}

///|
test "Hangul L and V compose algorithmically" {
  assert_eq(compose_canonical([0x1100, 0x1161]), [0xAC00])
}

///|
test "Hangul LV and T compose algorithmically" {
  assert_eq(compose_canonical([0xAC00, 0x11A8]), [0xAC01])
}

///|
test "compatibility-only values are not composed" {
  assert_eq(compose_canonical([0x0041, 0x00A0]), [0x0041, 0x00A0])
}
