
from std/strutils import toLowerAscii

func Py_parse_inf_or_nan*(res: var float, ori_s: openArray[char]): bool =
  ## a variant of `_Py_parse_inf_or_nan` in Python/pystrtod.c
  ## returns if successfully parses
  ## XXX: don't use parseFloat in std/strutils currently as it does not
  ## respect sign bit of `NaN`s.
  func iStartsWith(a, b: openArray[char]): bool =  
    ## b must be in lower case
    if b.len > a.len: return false
    result = true
    for i, c in b:
      if a[i].toLowerAscii != c:
        return false
  func `~=`(a, b: openArray[char]): bool =
    ## b must be in lower case
    if a.len != b.len:
      return false
    a.iStartsWith b
  result = true
  var negate = false
  let first = ori_s[0]
  let start =
    if first == '-': negate = true; 1
    elif first == '+': 1
    else: 0
  var s = ori_s[start..^1]

  if s.iStartsWith"inf":
    s = s[3..^1]
    if not (s.len == 0 or s ~= "inity"):
      return false
    res = if negate: NegInf else: Inf
  elif s ~= "nan":
    res = if negate: -abs(NaN) else: abs(NaN)
  else:
    return false
