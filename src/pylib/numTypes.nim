
import std/strutils except strip
import std/unicode
import std/bitops
import std/math
import ./pyerrors/rterr
import ./pystring/strimpl
import ./pybytes/bytesimpl

import ./private/backendMark


type NimInt* = system.int  ## alias of system.int

## TODO: later may allow to switch to bigints when compile

template prep(a: PyStr|PyBytes): string =
  bind strip
  strip $a

template int*(a: PyStr|PyBytes): NimInt =
  bind parseInt, prep
  parseInt(a.prep)
template int*(a: char): NimInt =
  bind parseInt
  parseInt($a)
template int*(a: bool): NimInt = (if a: 1 else: 0)
template int*(f: float): NimInt = system.int(f)

template nimint*(a): NimInt =
  bind int
  int(a)

func parseIntPrefix(x: string): int =
  ## returns:
  ## 
  ## * -1 if no prefix found
  ## * -2 if invald prefix
  ## 
  ## Never returns 0
  if x[0] == '0':
    case x[1].toLowerAscii
    of 'b': 2
    of 'o': 8
    of 'x': 16
    else: -2
  else: -1

func parseIntWithBase(x: string, base: int): int =
  case base
  of 2: result = parseBinInt x
  of 8: result = parseOctInt x
  of 16: result = parseHexInt x
  of 0:
    let prefixBase = parseIntPrefix x
    if prefixBase < 0:
      raise newException(ValueError,
        "invalid literal for int() with base 0: " & x.repr)
    result = parseIntWithBase(x, prefixBase)
  elif base in 3..32:
    raise newException(NotImplementedError,
      "only 2, 8, 16 based int parsing is supported currently")
  else:
    raise newException(ValueError, "int() base must be >= 2 and <= 36, or 0")

template int*(x: PyStr|PyBytes; base: int): NimInt =
  ## allowed base
  bind parseIntWithBase, prep
  parseIntWithBase(x.prep, base)

{.pragma: unsupLong, deprecated:
  """long(a.k.a. PyLong) is not supported, 
currently it's just a alias of BiggestInt (e.g. int64 on 64bit system)""".}

template long*(a: string): BiggestInt{.unsupLong.} = parseBiggestInt(a)
template long*(a: char): BiggestInt{.unsupLong.} = parseBiggestInt($a)
template long*[T: SomeNumber](a: T): BiggestInt{.unsupLong.} = BiggestInt(a)
template long*(a: bool): int{.unsupLong.} = BiggestInt(if a: 1 else: 0)

template float*(a: PyStr|PyBytes): BiggestFloat =
  bind parseFloat, prep
  parseFloat(a.prep)
template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)

using self: NimInt
template newInt(): NimInt = NimInt(0)
template getSize(self: NimInt): int = sizeof(NimInt) # sizeof cannot be overloaded
template fitLen(_: var NimInt, nbyte: int): bool = nbyte <= sizeof(NimInt)

template as_integer_ratio*(self: NimInt): (NimInt, NimInt) =
  (self, 1)

template bit_length*(self: NimInt): NimInt =
  bind fastLog2, abs
  1 + fastLog2 abs(self)

template conjugate*(self: NimInt): NimInt = self

func parseByteOrder(byteorder: string): Endianness =
  if byteorder == "little": result = littleEndian
  elif byteorder == "big": result = bigEndian
  else: raise newException(ValueError, "byteorder must be either 'little' or 'big'")

const BigEndian = cpuEndian == bigEndian
proc transInOrder(outBuf: var openArray[char], inBuf: openArray[char], endianness: Endianness,
    length, totLen: int) =
  template asgnWithI(inp, outp){.dirty.} =
    for i in 0..<length:
      outBuf[outp] = inBuf[inp]
  let hi_len = length - 1
  template handleTargetOrder(inp){.dirty.} =
    if endianness == bigEndian:
      asgnWithI(inp, hi_len - i)  # write from higher order.
    else:
      asgnWithI(inp, i)
  when BigEndian:
    let hi_tot = totLen - 1
    handleTargetOrder hi_tot - i  # read from higher order.
  else:
    handleTargetOrder i

template highByte(b: PyBytes): uint8 =
  uint8:
    when BigEndian: b[0]
    else: b[^1]

template signbitSet(b: uint8): bool =
  (b and 0b1000_0000'u8) == 0b1000_0000'u8

func lowestN_set0_and_rest_setP1[I](totByteLen: static[int], nByte: int): I =
  ## let the byte containing the sign bit is the highest.
  ## 0-fill the lowset `nByte` byte and
  ## 1-fill(all bit as 1) the rest (usually including sign bit).
  assert sizeof(I) == totByteLen
  block:
    var arr: array[totByteLen, int8]  # init with 0
    template P1range: untyped =
      when BigEndian: 0..<(totByteLen-nByte)
      else: nByte..<totByteLen
    for i in P1range:
      arr[i] = -1
    cast[I](arr)

proc from_bytes(res: var NimInt, bytes: PyBytes, byteorder: Endianness, signed=false) =
  if not res.fitLen bytes.len:
    raise newException(OverflowDefect, "Currently NimInt cannot hold so many bytes")

  const totByteLen = getSize(res)

  var holder: array[totByteLen, char]  # Nim init things with zero by default
  let bytesArr = @bytes
  transInOrder holder, bytesArr, byteorder, length=bytes.len, totLen=totByteLen
  res = cast[NimInt](holder)
  if signed:
    let bLen = bytes.len
    if bytes.highByte().signbitSet():
      res = res or lowestN_set0_and_rest_setP1[NimInt](totByteLen, bLen)
      #debugecho "byte: ", res.toBin(64)

  if not signed and res < 0:
    raise newException(OverflowDefect, 
      "signed=false now, but this value has caused overflow")

proc from_bytes*(_: typedesc[NimInt], bytes: PyBytes, byteorder: PyStr, signed=false): NimInt
    {.noWeirdBackend.} =
  let endianness = parseByteOrder $byteorder
  result = newInt()
  result.from_bytes(bytes, endianness, signed)

proc to_bytes*(self; length: int, byteorder: PyStr, signed=false): PyBytes
    {.noWeirdBackend.} =
  if length < 0:
    raise newException(ValueError, "length argument must be non-negative")
  if not signed and self < 0:
    raise newException(OverflowDefect, "can't convert negative int to unsigned")
  let endianness = parseByteOrder $byteorder

  let bitLen = self.bit_length()
  let byteLen = ceilDiv(bitLen, 8)
  const totByteLen = getSize(self)
  if byteLen > length:
    raise newException(OverflowDefect, "int too big to convert")
  let cstr = cast[array[totByteLen, char]](self)
  var s = newString(length)
  transInOrder s, cstr, endianness, length = length, totLen = totByteLen
  bytes s
