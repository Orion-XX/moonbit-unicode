///|
test "reorders non-starters by CCC within a starter run" {
  assert_eq(reorder_canonical([0x41, 0x0300, 0x0316, 0x0315]), [
    0x41, 0x0316, 0x0300, 0x0315,
  ])
}

///|
test "leading non-starters are ordered without a starter" {
  assert_eq(reorder_canonical([0x0300, 0x0316, 0x0315]), [
    0x0316, 0x0300, 0x0315,
  ])
}

///|
test "equal CCC values retain stable input order" {
  // U+0342 and U+0300 both have CCC 230.
  assert_eq(reorder_canonical([0x0342, 0x0300, 0x0316]), [
    0x0316, 0x0342, 0x0300,
  ])
}

///|
test "starter boundaries prevent cross-run reordering" {
  assert_eq(reorder_canonical([0x41, 0x0300, 0x0316, 0x42, 0x0315, 0x0300]), [
    0x41, 0x0316, 0x0300, 0x42, 0x0300, 0x0315,
  ])
}

///|
test "long combining-mark runs remain ordered" {
  assert_eq(
    reorder_canonical([
      0x41, 0x0315, 0x0316, 0x0300, 0x0317, 0x0318, 0x0301, 0x0319,
    ]),
    [0x41, 0x0316, 0x0317, 0x0318, 0x0319, 0x0300, 0x0301, 0x0315],
  )
}
