// Unicode 16.0.0 extended grapheme cluster boundaries.

///|
/// Return ascending, end-exclusive UTF-8 byte ranges for extended grapheme
/// clusters. The iterator owns a newly allocated range array and does not
/// retain input slices. Scalar decoding and malformed-input behavior inherit
/// MoonBit `String::iter`; this API does not decode raw bytes.
pub fn grapheme_boundaries(input : String) -> Iter[(Int, Int)] {
  let scalars : Array[GraphemeScalar] = []
  let mut byte_offset = 0
  input
  .iter()
  .each(ch => {
    let cp = ch.to_int()
    let next = byte_offset + utf8_width(cp)
    scalars.push({ cp, start: byte_offset, end: next })
    byte_offset = next
  })
  let boundaries : Array[(Int, Int)] = []
  if scalars.length() == 0 {
    return boundaries.iter()
  }
  let mut cluster_start = scalars[0].start
  let mut previous = scalars[0].property()
  let mut ri_run = if previous is RegionalIndicator { 1 } else { 0 }
  let mut ep_extend_run = is_extended_pictographic(scalars[0].cp)
  let mut zwj_after_ep = false
  for index = 1; index < scalars.length(); index = index + 1 {
    let current = scalars[index]
    let current_property = current.property()
    if grapheme_break_before(
        scalars[index - 1].cp,
        previous,
        current.cp,
        current_property,
        ri_run,
        zwj_after_ep,
      ) {
      boundaries.push((cluster_start, current.start))
      cluster_start = current.start
    }
    if current_property is RegionalIndicator {
      ri_run = if previous is RegionalIndicator { ri_run + 1 } else { 1 }
    } else {
      ri_run = 0
    }
    zwj_after_ep = current_property is ZWJ && ep_extend_run
    ep_extend_run = if is_extended_pictographic(current.cp) {
      true
    } else if current_property is Extend {
      ep_extend_run
    } else {
      false
    }
    previous = current_property
  }
  boundaries.push((cluster_start, scalars[scalars.length() - 1].end))
  boundaries.iter()
}

///|
priv struct GraphemeScalar {
  cp : Int
  start : Int
  end : Int
}

///|
fn GraphemeScalar::property(self : GraphemeScalar) -> GraphemeProperty {
  find_grapheme_break_property(self.cp)
}

///|
fn utf8_width(cp : Int) -> Int {
  if cp <= 0x7F {
    1
  } else if cp <= 0x7FF {
    2
  } else if cp <= 0xFFFF {
    3
  } else {
    4
  }
}

///|
fn grapheme_break_before(
  previous_cp : Int,
  previous : GraphemeProperty,
  current_cp : Int,
  current : GraphemeProperty,
  ri_run : Int,
  zwj_after_ep : Bool,
) -> Bool {
  // GB3.
  if previous is CR && current is LF {
    return false
  }
  // GB4/GB5.
  if is_control_like(previous) || is_control_like(current) {
    return true
  }
  // GB6--GB8.
  if previous is L &&
    (current is L || current is V || current is LV || current is LVT) {
    return false
  }
  if (previous is LV || previous is V) && (current is V || current is T) {
    return false
  }
  if (previous is LVT || previous is T) && current is T {
    return false
  }
  // GB9/GB9a.
  if current is Extend || current is ZWJ || current is SpacingMark {
    return false
  }
  // GB9b.
  if previous is Prepend {
    return false
  }
  // GB11.
  if previous is ZWJ && zwj_after_ep && is_extended_pictographic(current_cp) {
    return false
  }
  // GB12/GB13.
  if previous is RegionalIndicator && current is RegionalIndicator {
    return ri_run % 2 == 0
  }
  // GB999.
  ignore(previous_cp)
  true
}

///|
priv enum GraphemeProperty {
  Other
  Control
  CR
  Extend
  L
  LF
  LV
  LVT
  Prepend
  RegionalIndicator
  SpacingMark
  T
  V
  ZWJ
}

///|
fn find_grapheme_break_property(cp : Int) -> GraphemeProperty {
  for entry in @tables.grapheme_break_ranges {
    if cp >= entry.start && cp <= entry.end {
      return match entry.property {
        @tables.GraphemeBreakProperty::Other => Other
        @tables.GraphemeBreakProperty::Control => Control
        @tables.GraphemeBreakProperty::CR => CR
        @tables.GraphemeBreakProperty::Extend => Extend
        @tables.GraphemeBreakProperty::L => L
        @tables.GraphemeBreakProperty::LF => LF
        @tables.GraphemeBreakProperty::LV => LV
        @tables.GraphemeBreakProperty::LVT => LVT
        @tables.GraphemeBreakProperty::Prepend => Prepend
        @tables.GraphemeBreakProperty::RegionalIndicator => RegionalIndicator
        @tables.GraphemeBreakProperty::SpacingMark => SpacingMark
        @tables.GraphemeBreakProperty::T => T
        @tables.GraphemeBreakProperty::V => V
        @tables.GraphemeBreakProperty::ZWJ => ZWJ
      }
    }
  }
  Other
}

///|
fn is_extended_pictographic(cp : Int) -> Bool {
  for entry in @tables.extended_pictographic_ranges {
    if cp >= entry.start && cp <= entry.end {
      return true
    }
  }
  false
}

///|
fn is_control_like(property : GraphemeProperty) -> Bool {
  property is Control || property is CR || property is LF
}
