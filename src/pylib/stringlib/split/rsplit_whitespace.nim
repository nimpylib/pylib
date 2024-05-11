
import ./common
import ./reimporter
# translated from CPython-3.13-alpha.6/Objects/
#  stringlib/split.h
#  unicodeobject.c

# stringlib/split.h rsplit_whitespace L193

# split.h split* have param of `PyObject* str_obj, const STRINGLIB_CHAR* str`,
# where `str` is unicode version of `str_obj`
iterator rsplit_whitespace_impl[S](pystr: S, maxsplit, str_len: int): S =
  ## in reversed order
  ## 
  ## `maxsplit` must be Natural
  template SPLIT_ADD(s, i, j) = yield s[i..<j]
  template SPLIT_ADD(s) = yield s
  
  var i, j = str_len - 1

  var maxcount = maxsplit
  
  while maxcount.`suf--` > 0:
    while i >= 0 and pystr.ISSPACE(i):
      i.dec
    if i < 0: break
    j = i; i.dec
    while i >= 0 and not pystr.ISSPACE(i):
      i.dec
    when not STRINGLIB_MUTABLE:
      if j == str_len - 1 and i < 0:
        # here CPython checks `STRINGLIB_CHECK_EXACT` (L74)
        # as they need to use `PyUnicode_CheckExact` to ensure
        # `str_obj` is extractly a `str`, which we has ensured.
        SPLIT_ADD pystr
        break
    SPLIT_ADD pystr, i+1, j+1
  
  if i >= 0:
    while i >= 0 and pystr.ISSPACE(i):
      i.dec
    if i >= 0:
      SPLIT_ADD pystr, 0, i+1


proc rsplit_whitespace*[S](pystr: S, maxsplit = -1): PyList[S] =
  let
    str_len = len(pystr)
    maxcount = norm_maxsplit(maxsplit, str_len)
  result = newPyListOfCap[S](PREPARE_CAP(maxcount))
  for i in pystr.rsplit_whitespace_impl(str_len=str_len, maxsplit=maxcount):
    result.append i
  result.reverse()
