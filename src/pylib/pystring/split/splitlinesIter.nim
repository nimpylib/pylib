
from std/unicode import Rune
import ./common
from ./reimporter import splitlines

# Table of https://docs.python.org/3/library/stdtypes.html#str.splitlines
const LineBreaks = [
  Rune '\r',
  Rune '\n',
  Rune '\v',
  Rune '\x1c',
  Rune '\x1d',
  Rune '\x1e',
  Rune '\x85',
  Rune 0x2028,
  Rune 0x2029
]

template IS_LINKBREAK(str: PyStr, pos): bool =
  str.runeAtPos(pos) in LineBreaks

template IS_CAR_NL(s: PyStr, pos, str_len): bool =
  s[pos] == '\r' and pos + 1 < str_len and self[pos+1] == '\n'

iterator splitlines*(self: PyStr, keepends = false): PyStr =
  for i in splitlines[PyStr](self, keepends):
    yield i
