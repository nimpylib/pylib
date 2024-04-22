import std/times

{.experimental: "forLoopMacros".}

test "Python-like types":
  check True == true
  check False == false
  check bool("foo") == True
  check bool("") == False

test "divmod":
  check divmod(666, 1024) == (0, 666)
  check divmod(4, 2) == (2, 0)
  check divmod(4.int8, 2.int8) == (2'i8, 0'i8)

test "pass":
  pass 42  # Mimic pass, instead of discard, not exactly the same but close.
  pass true
  pass 1.2
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


test "bin()":
  check bin(1) == "0b1"
  check bin(6) == "0b110"
  when NimMajor > 1:
    when compileOption("jsBigInt64"):
      check bin(32587328532) == "0b11110010110010110110010110000010100"
      check bin(-140140140140) == "-0b10000010100001000000001101011001101100"
