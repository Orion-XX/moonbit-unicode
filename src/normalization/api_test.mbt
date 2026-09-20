///|
test "public NFD handles empty and ASCII fast paths" {
  let empty = ""
  let ascii = "plain ASCII"
  assert_eq(nfd(empty), empty)
  assert_eq(nfd(ascii), ascii)
  assert_eq(nfc(empty), empty)
  assert_eq(nfc(ascii), ascii)
}

///|
test "public NFD and NFC normalize a Latin pair" {
  let decomposed = "A\u{0300}"
  let composed = "\u{00C0}"
  assert_eq(nfd(composed), decomposed)
  assert_eq(nfc(decomposed), composed)
}

///|
test "public APIs are idempotent on targeted values" {
  let values = ["", "plain", "A\u{0300}", "\u{00C0}", "\u{AC01}"]
  for value in values {
    assert_eq(nfd(nfd(value)), nfd(value))
    assert_eq(nfc(nfc(value)), nfc(value))
    assert_eq(nfc(nfd(value)), nfc(value))
  }
}
