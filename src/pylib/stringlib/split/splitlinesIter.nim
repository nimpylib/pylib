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

import ./common
# L336

iterator splitlines*[S](self: S, keepends = false): S =
  ## mixin IS_CAR_NL, IS_LINEBREAK, [Slice], [int], len
  template SPLIT_ADD(s, i, j) = yield s[i..<j]
  let str_len = len(self)
  var i, j = 0
  while i < str_len:
    var eol: int

    # Find a line and append it
    while i < str_len and not self.IS_LINKBREAK(i):
      i.inc
    
    # Skip the line break reading CRLF as one line break
    eol = i
    if i < str_len:
      if self.IS_CAR_NL(i, str_len):
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
