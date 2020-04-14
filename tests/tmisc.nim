import times


from pylib/future import braces
#import pylib/antigravity

`import`("strutils")  # __import__()


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

  if (a := 6) > 5:
    assert a == 6

  if (b := 42.0) > 5.0:
    assert b == 42.0

  if (c := "hello") == "hello":
    assert c == "hello"

  if (d := 'z') == 'z':
    assert d == 'z'

  checkpoint "Timeit"
  timeit(9):
    discard
