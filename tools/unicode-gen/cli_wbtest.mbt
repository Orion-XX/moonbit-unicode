///|
test "reserved commands fail closed with the supplied data path" {
  for command in ["check", "generate", "import-tests"] {
    let error = command_error([command, "--data", "missing/16.0.0"])
    assert_true(error.contains("U-00 scaffold"))
    assert_true(error.contains(command))
    assert_true(error.contains("missing/16.0.0"))
    assert_true(error.contains("missing data is never accepted"))
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
    assert_true(command_error(args).contains("usage:"))
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
