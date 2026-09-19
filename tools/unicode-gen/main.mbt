///|
// U-00 reserves the CLI contract, without inspecting or generating Unicode data.
// Always fail closed until the corresponding data/parser/generation tasks land.
fn command_error(args : Array[String]) -> String {
  match args[:] {
    [command, "--data", path] if (
        command == "check" || command == "generate" || command == "import-tests"
      ) &&
      path != "" =>
      "unicode-gen: U-00 scaffold: \{command} unavailable for data path '\{path}'; missing data is never accepted. Pinned inputs and verification require U-01; parsing/generation/import require later tasks."
    _ => "unicode-gen: usage: <check|generate|import-tests> --data <directory>"
  }
}

///|
// core/env exposes Node's process.argv (node + script), but other runners
// include only the executable before the user arguments.
#cfg(target="js")
fn user_args(args : Array[String]) -> Array[String] {
  args[2:].to_owned()
}

///|
#cfg(not(target="js"))
fn user_args(args : Array[String]) -> Array[String] {
  args[1:].to_owned()
}

///|
fn main {
  let args = @env.args()
  let diagnostic = command_error(user_args(args))
  println(diagnostic)
  // Core has no portable process-exit API. Panic ensures a nonzero exit on
  // every backend without adding host FFI or a dependency just for the stub.
  panic()
}
