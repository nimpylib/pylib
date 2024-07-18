
test "int.{from,to}_bytes":
  checkpoint "int.to_bytes"
  check (1).to_bytes(1, "big") == b"\x01"
  check (1).to_bytes(2, "big") == b"\x00\x01"
  check (1).to_bytes(2, "little") == b"\x01\x00"
  check (-2).to_bytes(2, "little", signed=true) == b"\xfe\xff"

  checkpoint "int.from_bytes"
  check NimInt.from_bytes(b"", "big", signed=true) == 0
  check NimInt.from_bytes(b"", "big", signed=true) == 0
  check NimInt.from_bytes(b"\x01\x00", "little") == 1
  check NimInt.from_bytes(b"\x00\x01", "big") == 1
  check NimInt.from_bytes(b"\xfe\xff", "little", signed=true) == -2
  check NimInt.from_bytes(b"\xfe\xff", "big", signed=true) == -257
  check NimInt.from_bytes(b"\x00\xff", "big", signed=true) == 255
