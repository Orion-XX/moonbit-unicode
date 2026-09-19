// U-04: canonical decomposition stage for Unicode 16.0.0.
//
// This stage deliberately does not reorder combining marks. Canonical
// ordering is the responsibility of U-05.

///|
const S_BASE : Int = 0xAC00

///|
const L_BASE : Int = 0x1100

///|
const V_BASE : Int = 0x1161

///|
const T_BASE : Int = 0x11A7

///|
const L_COUNT : Int = 19

///|
const V_COUNT : Int = 21

///|
const T_COUNT : Int = 28

///|
const N_COUNT : Int = V_COUNT * T_COUNT

///|
const S_COUNT : Int = L_COUNT * N_COUNT

///|
fn find_canonical(cp : Int) -> @tables.CanonicalDecomposition? {
  for entry in @tables.canonical_decompositions {
    if entry.cp == cp {
      return Some(entry)
    }
  }
  None
}

///|
fn decompose_hangul(cp : Int, output : Array[Int]) -> Bool {
  let s_index = cp - S_BASE
  if s_index < 0 || s_index >= S_COUNT {
    return false
  }
  let l_index = s_index / N_COUNT
  let v_index = s_index % N_COUNT / T_COUNT
  let t_index = s_index % T_COUNT
  output.push(L_BASE + l_index)
  output.push(V_BASE + v_index)
  if t_index != 0 {
    output.push(T_BASE + t_index)
  }
  true
}

///|
fn decompose_scalar(cp : Int, output : Array[Int]) -> Unit {
  if decompose_hangul(cp, output) {
    return
  }
  match find_canonical(cp) {
    Some(entry) =>
      for mapped in entry.mapping {
        decompose_scalar(mapped, output)
      }
    None => output.push(cp)
  }
}

///|
/// Recursively decompose canonical mappings and algorithmic Hangul syllables.
/// The returned scalar sequence retains input order; it is not CCC-reordered.
fn decompose_canonical(input : Array[Int]) -> Array[Int] {
  let output : Array[Int] = []
  for cp in input {
    decompose_scalar(cp, output)
  }
  output
}
