
import ./common
import ./reimporter
# translated from CPython-3.13-alpha.6/Objects/
#  stringlib/split.h
#  unicodeobject.c

# stringlib/split.h split_whitespace L54
func `suf--`(i: var int): int{.inline.} =
  ## `i--` in C
  result = i
  i.dec

const STRINGLIB_MUTABLE = false  # XXX: What's this?
# in all of asciilib.h, ucs{1,2,4}lib.h, just define as `0`

template ISSPACE(s, pos): bool =
  ## Checks unicode space at unicode char's `pos`
  s.runeAtPos(pos) in unicodeSpaces

# unicodeobject.c split L9876
template norm_maxsplit(maxsplit: int, len1): int =
  if maxsplit < 0: (len1 - 1) div 2 + 1
  else: maxsplit

# split.h split* have param of `PyObject* str_obj, const STRINGLIB_CHAR* str`,
# where `str` is unicode version of `str_obj`
iterator split_whitespace_impl(pystr: PyStr, maxsplit, str_len: int): PyStr =
  ## `maxsplit` must be Natural
  template SPLIT_ADD(s, i, j) = yield s[i..<j]
  template SPLIT_ADD(s) = yield s
  var i, j: int

  var maxcount = maxsplit
  
  while maxcount.`suf--` > 0:
    while i < str_len and ISSPACE(pystr, i):
      i.inc
    if i == str_len: break
    j = i; i.inc
    while i < str_len and not ISSPACE(pystr, i):
      i.inc
    when not STRINGLIB_MUTABLE:
      if j == 0 and i == str_len:
        # here CPython checks `STRINGLIB_CHECK_EXACT` (L74)
        # as they need to use `PyUnicode_CheckExact` to ensure
        # `str_obj` is extractly a `str`, which we has ensured.
        SPLIT_ADD pystr
        break
    SPLIT_ADD pystr, j, i
  
  if i < str_len:
    while i < str_len and ISSPACE(pystr, i):
      i.inc
    if i != str_len:
      SPLIT_ADD pystr, i, str_len


iterator split_whitespace*(pystr: PyStr, maxsplit = -1): PyStr =
  let str_len = len(pystr)
  let maxcount = norm_maxsplit(maxsplit, str_len)

  for i in pystr.split_whitespace_impl(str_len=str_len, maxsplit=maxcount):
    yield i

proc split_whitespace*(pystr: PyStr, maxsplit = -1): PyList[PyStr] =
  let
    str_len = len(pystr)
    maxcount = norm_maxsplit(maxsplit, str_len)
  result = newPyListOfCap[PyStr](PREPARE_CAP(maxcount))
  for i in pystr.split_whitespace_impl(str_len=str_len, maxsplit=maxcount):
    result.append i
