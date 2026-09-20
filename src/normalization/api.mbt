// Public canonical normalization APIs for Unicode 16.0.0.

///|
/// Normalize `input` to Unicode Normalization Form D (NFD).
///
/// The implementation uses the Unicode 16.0.0 canonical decomposition and
/// canonical-combining-class data bundled with this package. The returned
/// string is newly constructed when normalization work is needed; empty and
/// ASCII-only inputs use an allocation-free fast path and are returned as-is.
/// Input is a MoonBit `String`, so scalar decoding and malformed UTF-8
/// behavior are inherited from `String::iter` and `String::from_array`; this
/// API does not accept raw byte buffers or add another decoder.
pub fn nfd(input : String) -> String {
  if is_ascii(input) {
    return input
  }
  let scalars : Array[Int] = []
  input.iter().each(ch => scalars.push(ch.to_int()))
  scalars |> decompose_canonical |> reorder_canonical |> scalars_to_string
}

///|
/// Normalize `input` to Unicode Normalization Form C (NFC).
///
/// The implementation uses the Unicode 16.0.0 canonical decomposition,
/// ordering, and composition data bundled with this package, including
/// canonical blocking and algorithmic Hangul composition. The returned string
/// is newly constructed when normalization work is needed; empty and
/// ASCII-only inputs use an allocation-free fast path and are returned as-is.
/// Input is a MoonBit `String`, so scalar decoding and malformed UTF-8
/// behavior are inherited from `String::iter` and `String::from_array`; this
/// API does not accept raw byte buffers or add another decoder.
pub fn nfc(input : String) -> String {
  if is_ascii(input) {
    return input
  }
  let scalars : Array[Int] = []
  input.iter().each(ch => scalars.push(ch.to_int()))
  scalars
  |> decompose_canonical
  |> reorder_canonical
  |> compose_canonical
  |> scalars_to_string
}

///|
/// Return true for strings whose scalar sequence cannot be changed by
/// canonical normalization. This also covers the empty string.
fn is_ascii(input : String) -> Bool {
  for ch in input.iter() {
    if ch.to_int() > 0x7F {
      return false
    }
  }
  true
}

///|
fn scalars_to_string(scalars : Array[Int]) -> String {
  String::from_array(scalars.map(cp => cp.unsafe_to_char()))
}
