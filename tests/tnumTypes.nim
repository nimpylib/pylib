
test "int(x[, base])":
  let i = int("12")
  check i == 12

  var ii{.used.}: seq[int]  ## test if int can be used as a type

  check int("a", 16) == 10

  expect ValueError:
    discard int("1", 33)
