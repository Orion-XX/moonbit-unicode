///|
test "reserved commands fail closed with the supplied data path" {
  for command in ["check", "generate", "import-tests"] {
    let result = command_result([command, "--data", "missing/16.0.0"])
    assert_true(result is Ok(_))
  }
}

///|
test "invalid CLI shapes report usage" {
  for
    args in [
      [],
      ["check"],
      ["check", "--data"],
      ["check", "--data", ""],
      ["unknown", "--data", "data"],
      ["--data", "data", "check"],
      ["check", "--data", "data", "extra"],
    ] {
    match command_result(args) {
      Ok(_) => assert_true(false)
      Err(message) => assert_true(message.contains("usage:"))
    }
  }
}

///|
#cfg(target="js")
test "Node and script prefixes are removed without losing the command" {
  assert_eq(user_args(["node", "unicode-gen.js", "check"]), ["check"])
  assert_eq(user_args(["node", "unicode-gen.js"]), [])
}

///|
#cfg(not(target="js"))
test "executable prefix is removed without losing the command" {
  assert_eq(user_args(["unicode-gen", "check"]), ["check"])
  assert_eq(user_args(["unicode-gen"]), [])
}
