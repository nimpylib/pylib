test "Floor division":
  check(5.0 // 2 == 2.0)
  check(5 // 2 == 2)
  check(5 // 7 == 0)
  check(-10 // 3 == -4)
  check(5 // -6 == -1)
  check(5 // -2 == -3)
  check(5 // -3 == -2)
  check(5 // -3.0 == -2.0)
