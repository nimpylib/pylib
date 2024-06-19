
test "getattr/set/has":
  type
    O = object
      a: int

  var o = O()

  let aVal = 2
  setattr(o, "a", aVal)

  check 3 == getattr(o, "b", 3)

  check aVal == getattr(o, "a")

  check not hasattr(o, "b")
