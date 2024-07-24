
import ./decl
import ../reimporter
from std/strutils import parseInt, parseBinInt, parseOctInt, parseHexInt, toLowerAscii
from std/unicode import strip

template int*(i: SomeInteger): NimInt = system.int(i)

template prep(a: PyStr|PyBytes): string =
  bind strip
  strip $a

template int*(a: PyStr|PyBytes): NimInt =
  bind parseInt, prep
  parseInt(prep a)
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
  parseIntWithBase(prep x, base)
