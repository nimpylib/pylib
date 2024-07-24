
from std/math import ceilDiv
import ./decl
import ./nint_proto
import ../reimporter
const weridTarget = defined(js) or defined(nimscript)

func parseByteOrder(byteorder: string): Endianness =
  if byteorder == "little": result = littleEndian
  elif byteorder == "big": result = bigEndian
  else: raise newException(ValueError, "byteorder must be either 'little' or 'big'")

template highByte(b: PyBytes, endian: Endianness, hi = b.len-1): uint8 =
  uint8:
    if endian == bigEndian : b.getChar 0
    else: b.getChar hi

template signbitSet(b: uint8): bool =
  (b and 0b1000_0000'u8) == 0b1000_0000'u8

const arrNotCvtableInt = weridTarget

when arrNotCvtableInt:
  template charPart(i: NimInt): char =
    when compileOption("jsBigInt64"):
      # NIM-BUG: When char is unsigned, if only `cast[char](i)`
      # you'll get surprising a char with negative `ord` result!
      # (and converting it to int results in a negative int)
      char cast[uint8](i)
    else:
      cast[char](i)
  template loopRangeWithIt(bHi: int, byteorder: Endianness, body: untyped){.dirty.} =
    if byteorder == bigEndian:
      for it{.inject.} in countdown(bHi, 0): body
    else:
      for it{.inject.} in 0 .. bHi: body
else:
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

func add_from_bytes*(res: var NimInt, bytes: PyBytes, byteorder: Endianness, signed=false) =
  ## EXT.
  let bLen = bytes.len
  if bLen == 0:
    return
  if not res.fitLen bLen:
    raise newException(OverflowDefect, "Currently NimInt cannot hold so many bytes")
  let bHi = bytes.len - 1
  when arrNotCvtableInt:
    template loopWithIt(expr) =
      for it{.inject.} in 0..bHi:
        res += bytes[expr] shl (it*8)
    if byteorder == littleEndian:
      loopWithIt it
    else:
      loopWithIt bHi - it
    if signed and bytes.highByte(byteorder, bHi).signbitSet():
      # we've check bytes is not empty above
      res -= 1 shl (8 * bLen)
  else:
    const totByteLen = getSize(res)

    var holder: array[totByteLen, char]  # Nim init things with zero by default
    let bytesArr = @bytes
    transInOrder holder, bytesArr, byteorder, length=bytes.len, totLen=totByteLen
    res = cast[NimInt](holder)
    if signed and bytes.highByte(byteorder, bHi).signbitSet():
      # we've check bytes is not empty above
      # res -= 1 shl (8 * bLen) <- the same as following line
      res = res or lowestN_set0_and_rest_setP1[NimInt](totByteLen, bLen)

      #debugecho "byte: ", res.toBin(64)

  if not signed and res < 0:
    raise newException(OverflowDefect, 
      "signed=false now, but this value has caused overflow")

func from_bytes*(_: typedesc[NimInt], bytes: PyBytes, byteorder: PyStr, signed=false): NimInt{.pysince(3,2).} =
  let endianness = parseByteOrder $byteorder
  result = newInt()
  result.add_from_bytes(bytes, endianness, signed)

func from_bytes*(_: typedesc[NimInt], bytes: PyBytes,
    byteorder: static[PyStr] = str("big"), signed=false): NimInt{.pysince(3,11).} =
  ## this variant uses static param for byteorder
  const endianness = parseByteOrder $byteorder
  result = newInt()
  result.add_from_bytes(bytes, endianness, signed)

using self: NimInt
func to_chars*(self; length: int, endianness: Endianness, signed=false): seq[char] =
  ## EXT.
  if length < 0:
    raise newException(ValueError, "length argument must be non-negative")
  if not signed and self < 0:
    raise newException(OverflowDefect, "can't convert negative int to unsigned")

  let bitLen = self.bit_length()
  let byteLen = ceilDiv(bitLen, 8)
  if byteLen > length:
    raise newException(OverflowDefect, "int too big to convert")

  when arrNotCvtableInt:
    result = newSeqOfCap[char](length)
    loopRangeWithIt(length - 1, endianness):
      result.add (self shr (it*8)).charPart
  else:
    const totByteLen = getSize(self)
    result = newSeq[char](length)
    let cstr = cast[array[totByteLen, char]](self)
    transInOrder result, cstr, endianness, length = length, totLen = totByteLen

func to_bytes*(self; length: int, byteorder: PyStr, signed=false): PyBytes =
  let endianness = parseByteOrder $byteorder
  bytes self.to_chars(length, endianness, signed=signed)

func to_bytes*(self; length: int, byteorder: static[PyStr] = str("big"), signed=false
    ): PyBytes{.pysince(3,11).} =
  const endianness = parseByteOrder $byteorder
  bytes self.to_chars(length, endianness, signed=signed)
