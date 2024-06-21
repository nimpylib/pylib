
test "int(x[, base])":
  let i = int("12")
  check i == 12

  var ii{.used.}: seq[int]  ## test if int can be used as a type

  check int("a", 16) == 10

  expect ValueError:
    discard int("1", 33)

  checkpoint "with whitespace"

  check int(" -3") == -3

test "float(str)":
  check NegInf == float("-INF")
  let na = float("naN")
  check na != na  # NaN != NaN

test "int method":
  checkpoint "int.to_bytes"
  check (1).to_bytes(1, "big") == b"\x01"
  check (1).to_bytes(2, "big") == b"\x00\x01"
  check (1).to_bytes(2, "little") == b"\x01\x00"
  check (-2).to_bytes(2, "little", signed=true) == b"\xfe\xff"

  checkpoint "int.from_bytes"
  check NimInt.from_bytes(b"\x01\x00", "little") == 1
  check NimInt.from_bytes(b"\x00\x01", "big") == 1
  check NimInt.from_bytes(b"\xfe\xff", "little", signed=true) == -2
