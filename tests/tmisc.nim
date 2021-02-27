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
  check divmod(4.int8, 2.int8) == (2, 0)

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


when not defined(js):
  test "bin()":
    check bin(32587328532) == "0b11110010110010110110010110000010100"
    check bin(-140140140140) == "-0b10000010100001000000001101011001101100"

  test "filter()":
    # function that filters vowels
    proc fun(variable: char): bool =
      const letters = ['a', 'e', 'i', 'o', 'u']
      if (variable in letters):
        return true
      else:
        return false

    # sequence
    let sequence = ['g', 'e', 'e', 'j', 'k', 'i', 's', 'p', 'r', 'e', 'o']
    let filtered = filter(fun, sequence)
    let res = @['e', 'e', 'i', 'e', 'o']
    var data: seq[char]
    for s in filtered:
      data.add s

    check data == res
    data = @[]
    for s in filtered:
      data.add s

    check data == res
    check list(filtered) == res

    let otherData = @[0, 1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 0, 31254, 0]

    let other = filter(None, otherData)

    check list(other) == @[1, 2, 3, 4, 5, 6, 7, 8, -1, 12412, 31254]
