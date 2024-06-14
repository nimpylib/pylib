
import std/strutils except strip
import std/unicode
import ./pyerrors/rterr
import ./pystring/strimpl
import ./pybytes/bytesimpl


type Int* = system.int  ## alias of system.int

template prep(a: PyStr|PyBytes): string =
  bind strip
  strip $a

template int*(a: PyStr|PyBytes): Int =
  bind parseInt, prep
  parseInt(a.prep)
template int*(a: char): Int =
  bind parseInt
  parseInt($a)
template int*(a: bool): Int = (if a: 1 else: 0)

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

template int*(x: PyStr|PyBytes; base: int): Int =
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
