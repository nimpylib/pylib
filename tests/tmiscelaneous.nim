import times

test "Miscelaneous":
  check True == true
  check False == false
  check bool("foo") == True
  check bool("") == False

  check divmod(666, 1024) == [0, 666]
  check divmod(4, 2) == [2, 0]
  check divmod(4.int8, 2.int8) == [2, 0]

  pass 42  # Mimic pass, instead of discard, not exactly the same but close.
  pass true
  pass 1.2
  pass()
  pass "a"
  pass 'b'

  let arg = "hello"
  let anon = lambda: arg & " world"
  check anon() == "hello world"

  checkpoint "Timeit"
  timeit(9):
    discard
