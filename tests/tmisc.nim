import times

{.experimental: "forLoopMacros".}

test "Python-like types":
  check True == true
  check False == false
  check bool("foo") == True
  check bool("") == False

test "divmod":
  check divmod(666, 1024) == (0, 666)
  check divmod(4, 2) == (2, 0)
  check divmod(4.int8, 2.int8) == (2, 0)

test "pass":
  pass 42  # Mimic pass, instead of discard, not exactly the same but close.
  pass true
  pass 1.2
  pass()
  pass "a"
  pass 'b'

test "lambda":
  let arg = "hello"
  let anon = lambda: arg & " world"
  check anon() == "hello world"

test "walrus operator":
  if (a := 6) > 5:
    assert a == 6

  if (b := 42.0) > 5.0:
    assert b == 42.0

  if (c := "hello") == "hello":
    assert c == "hello"

  if (d := 'z') == 'z':
    assert d == 'z'

test "timeit":
  timeit(9):
    discard

test "enumerate() macro":
  let my_list = ["apple", "banana", "grapes", "pear"]

  var mycount = 0

  for counter, value in enumerate(my_list):
    check mycount == counter
    check my_list[counter] == my_list[mycount]
    inc mycount
  
  mycount = 0
  for counter, value in enumerate(my_list, 150):
    check mycount + 150 == counter
    check my_list[counter - 150] == my_list[mycount]
    inc mycount 

test "hex()":
  check hex(23) == "0x17"
  check hex(ord('a')) == "0x61"
  check hex(231582835) == "0xdcdac73"

test "chr()":
  check chr(65) == 'A'
  check chr(0x1F451) == "👑"

test "oct()":
  check oct(8) == "0o10"
  check oct(-56) == "-0o70"
  check oct(0) == "0o0"

test "ord()":
  check ord("👑") == 0x1F451
  check ord('A') == 65
