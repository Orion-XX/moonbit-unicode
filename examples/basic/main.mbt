///|
fn main {
  let decomposed = "e\\u{301}"
  let canonical = @normalization.nfc(decomposed)
  let round_trip = @normalization.nfd(canonical)
  let family = "👩‍👩‍👧‍👦"
  let boundaries = @grapheme.grapheme_boundaries(family).to_array()
  println("NFC: " + canonical)
  println(
    "NFD scalar count: " + round_trip.iter().to_array().length().to_string(),
  )
  println("Family grapheme byte ranges: " + boundaries.to_string())
}
