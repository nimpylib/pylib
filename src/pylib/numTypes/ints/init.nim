
import ./decl
import ../reimporter
import ../utils/stripOpenArray
from std/strutils import toLowerAscii
from std/parseutils import parseInt, parseBin, parseOct, parseHex

template int*(i: SomeInteger): NimInt = system.int(i)

func invalidInt(s: string, base: int) =
  raise newException(ValueError,
    "invalid literal for int() with base " & $base & ": " & s)

func int*(a: PyStr|PyBytes): NimInt =
  let sa = $a
  let (m, n) = (sa).stripAsRange
  template stripped: untyped = (sa).toOpenArray(m, n)
  let ni = parseInt(stripped, result)
  if ni == 0:
    invalidInt(repr(a), 10)

func int*(a: char): NimInt =
  result = system.int(a) -% system.int('0')  # never overflow, so use `-%`
  if result not_in 0..9:
    invalidInt(repr(a), 10)

template int*(a: bool): NimInt = (if a: 1 else: 0)
template int*(f: float): NimInt = system.int(f)


type HasIndex = concept self
  self.index() is SomeInteger
type HasTrunc = concept self
  self.trunc() is SomeInteger

template int*(obj: HasIndex): NimInt = NimInt obj.index()
template int*(obj: HasTrunc): NimInt = NimInt obj.trunc()
template int*(obj: HasIndex and HasIndex): NimInt = NimInt obj.index()

template nimint*(a): NimInt =
  bind int
  int(a)

func parseIntPrefix(x: openArray[char]): int =
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

type ParseIntError = object of CatchableError
  base*: int

func parseIntWithBase(x: openArray[char], base: int): int =
  template invalidInt(base_arg: int) =
    raise (ref ParseIntError)(base: base_arg)
  template chk(i: int) =
    if i != x.len:
      invalidInt(base)
  case base
  of 2: chk x.parseBin result
  of 8: chk x.parseOct result
  of 16: chk x.parseHex result
  of 0:
    let prefixBase = parseIntPrefix x
    if prefixBase < 0:
      invalidInt 0
    result = parseIntWithBase(x, prefixBase)
  elif base in 3..32:
    raise newException(NotImplementedError,
      "only 2, 8, 16 based int parsing is supported currently")
  else:
    raise newException(ValueError, "int() base must be >= 2 and <= 36, or 0")

func int*(a: PyStr|PyBytes; base: int): NimInt =
  ## allowed base
  let sa = $a
  let (m, n) = (sa).stripAsRange
  try:
    template stripped: untyped = (sa).toOpenArray(m, n)
    result = parseIntWithBase(stripped, base)
  except ParseIntError as e:
    invalidInt(repr(a), e.base)
