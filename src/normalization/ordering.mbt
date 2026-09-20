// U-05: canonical ordering stage for Unicode 16.0.0.
//
// Canonical ordering sorts non-starters by CCC within each starter-delimited
// run. Equal CCC values are kept in input order (stable ordering).

///|
fn combining_class(cp : Int) -> Int {
  for entry in @tables.combining_class_ranges {
    if cp >= entry.start && cp <= entry.end {
      return entry.ccc
    }
  }
  0
}

///|
fn insert_by_ccc(sorted : Array[Int], cp : Int) -> Array[Int] {
  let cp_ccc = combining_class(cp)
  let result : Array[Int] = []
  let mut inserted = false
  for item in sorted {
    // Strictly greater keeps equal-CCC marks stable.
    if !inserted && combining_class(item) > cp_ccc {
      result.push(cp)
      inserted = true
    }
    result.push(item)
  }
  if !inserted {
    result.push(cp)
  }
  result
}

///|
fn flush_ordered_run(run : Array[Int], output : Array[Int]) -> Unit {
  for cp in run {
    output.push(cp)
  }
}

///|
/// Reorder decomposed scalars by canonical combining class within each
/// starter-delimited run. The input and output are scalar sequences; this
/// stage does not compose or otherwise change scalar values.
fn reorder_canonical(input : Array[Int]) -> Array[Int] {
  let output : Array[Int] = []
  let mut run : Array[Int] = []
  for cp in input {
    if combining_class(cp) == 0 {
      flush_ordered_run(run, output)
      run = [cp]
    } else {
      run = insert_by_ccc(run, cp)
    }
  }
  flush_ordered_run(run, output)
  output
}
