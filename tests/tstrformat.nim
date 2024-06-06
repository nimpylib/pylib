
test "str.format":
  check "a {}  b".format(1) == "a 1  b"
  check "{0}0{0}".format(3) == "303"
