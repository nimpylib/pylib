## We cannot just use `strutils.splitLines` for str.splitlines,
##  even nor for `bytes.splitlines`,
## as Python uses Univeral NewLine as sep.
## 
## See https://docs.python.org/3/glossary.html#term-universal-newlines
## 
## For a table of all Universal Newlines, 
## see https://docs.python.org/3/library/stdtypes.html#str.splitlines

# So again, we refer to CPython's source.

# translated from CPython-3.13-alpha.6/Objects/
#  stringlib/split.h

from std/unicode import Rune
import ./common

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

template IS_LINKBREAK(str, pos): bool =
  str.runeAtPos(pos) in LineBreaks

# L336

iterator splitlines*(self: PyStr, keepends = false): PyStr =
  template SPLIT_ADD(s, i, j) = yield s[i..<j]
  let str_len = len(self)
  var i, j = 0
  while i < str_len:
    var eol: int

    # Find a line and append it
    while i < str_len and not IS_LINKBREAK(self, i):
      i.inc
    
    # Skip the line break reading CRLF as one line break
    eol = i
    if i < str_len:
      if self[i] == '\r' and i + 1 < str_len and self[i+1] == '\n':
        i.inc 2
      else:
        i.inc
      if keepends:
        eol = i
    when not STRINGLIB_MUTABLE:
      if j == 0 and eol == str_len:
        # No linebreak in str_obj, so just use it
        yield self
        break
    SPLIT_ADD self, j, eol
    j = i
