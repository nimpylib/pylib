

from std/strutils import toBin, toOct, toHex, toLowerAscii, strip

proc absInt[T: SomeSignedInt](x: T): T{.inline.} =
  ## For JS,
  ## Between nim's using BigInt and 
  ## this [patch](https://github.com/nim-lang/Nim/issues/23378)
  ##   `system.abs` will gen: `(-1)*x`, which can lead to a runtime err
  ## as `x` may be a `bigint`, which causes error:
  ##    Uncaught TypeError: Cannot mix BigInt and other types, ...
  if x < 0.T: result = T(-1) * x
  else: result = x
template makeConv(name, call: untyped, len: int, pfix: string) =
  func `name`*(a: SomeInteger): string =
    # Special case
    if a == 0:
      return `pfix` & "0"
    result = call(
      when a isnot SomeUnsignedInt:
        absInt(a)
      else:
        a,
      `len`).toLowerAscii().strip(chars = {'0'}, trailing = false)
    # Do it like in Python - add - sign
    result.insert(`pfix`)
    when a isnot SomeUnsignedInt: # optimization
      if a < 0:
        result.insert "-"

# Max length is derived from the max value for uint64
makeConv(oct, toOct, 30, "0o")
makeConv(bin, toBin, 70, "0b")
makeConv(hex, toHex, 20, "0x")
