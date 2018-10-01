import times

test "Miscelaneous":
  check True == true
  check False == false
  check bool("foo") == True
  check bool("") == False

  check divmod(666, 1024) == [0, 666]
  check divmod(4, 2) == [2, 0]
  check divmod(4.int8, 2.int8) == [2, 0]

  checkpoint "Timeit"
  timeit(9):
    discard
