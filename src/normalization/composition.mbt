// U-06: canonical composition stage for Unicode 16.0.0.
//
// The input is expected to be canonically decomposed and ordered. Composition
// therefore only replaces a starter and a following, unblocked scalar.

///|
fn is_composition_excluded(cp : Int) -> Bool {
  @tables.composition_exclusions.contains(cp)
}

///|
fn compose_hangul(starter : Int, combining : Int) -> Int? {
  // UAX #15 algorithmic L + V -> LV.
  if starter >= L_BASE &&
    starter < L_BASE + L_COUNT &&
    combining >= V_BASE &&
    combining < V_BASE + V_COUNT {
    let l_index = starter - L_BASE
    let v_index = combining - V_BASE
    return Some(S_BASE + (l_index * V_COUNT + v_index) * T_COUNT)
  }
  // UAX #15 algorithmic LV + T -> LVT.
  if starter >= S_BASE &&
    starter < S_BASE + S_COUNT &&
    (starter - S_BASE) % T_COUNT == 0 &&
    combining > T_BASE &&
    combining <= T_BASE + T_COUNT - 1 {
    return Some(starter + combining - T_BASE)
  }
  None
}

///|
fn find_composition(starter : Int, combining : Int) -> Int? {
  for entry in @tables.composition_pairs {
    if entry.starter == starter && entry.combining == combining {
      if !is_composition_excluded(entry.composite) {
        return Some(entry.composite)
      }
      return None
    }
  }
  None
}

///|
fn compose_pair(starter : Int, combining : Int) -> Int? {
  match compose_hangul(starter, combining) {
    Some(composite) => Some(composite)
    None => find_composition(starter, combining)
  }
}

///|
/// Compose canonically decomposed and ordered scalars using UAX #15 blocking.
/// The result remains canonically composed but is not a public String API.
fn compose_canonical(input : Array[Int]) -> Array[Int] {
  let output : Array[Int] = []
  let mut starter_index : Int? = None
  let mut previous_ccc = 0
  for cp in input {
    let ccc = combining_class(cp)
    let mut composed = false
    match starter_index {
      Some(index) =>
        if previous_ccc == 0 || previous_ccc < ccc {
          match compose_pair(output[index], cp) {
            Some(composite) => {
              output[index] = composite
              composed = true
            }
            None => ()
          }
        }
      None => ()
    }
    if !composed {
      output.push(cp)
      if ccc == 0 {
        starter_index = Some(output.length() - 1)
        previous_ccc = 0
      } else {
        previous_ccc = ccc
      }
    }
  }
  output
}
