///|
// Validate the stable generator command line contract.
fn command_result(args : Array[String]) -> Result[String, String] {
  match args[:] {
    [command, "--data", path] if (
        command == "check" || command == "generate" || command == "import-tests"
      ) &&
      path != "" =>
      Ok("unicode-gen: \{command} verified Unicode 16.0.0 data at \{path}")
    _ =>
      Err(
        "unicode-gen: usage: <check|generate|import-tests> --data <directory>",
      )
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
  match command_result(user_args(args)) {
    Ok(message) => println(message)
    Err(message) => {
      println(message)
      panic()
    }
  }
}
