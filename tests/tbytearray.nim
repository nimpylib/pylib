
test "bytearray":
  var ba = bytearray()

  check ba.len == 0
  ba += b"abc"

  check ba[2] == ord('c')

  checkpoint "check byte-like method"

  check ba.isascii()

  ba.reverse()

  check ba == b"cba"
