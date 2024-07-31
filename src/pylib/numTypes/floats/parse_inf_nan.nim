
from std/strutils import toLowerAscii

func parse_inf_or_nan*(ori_s: openArray[char], res: var float): int =
  ## a variant of `_Py_parse_inf_or_nan` in Python/pystrtod.c
  ## XXX: don't use parseFloat in std/parseutils currently as it does not
  ## respect sign bit of `NaN`s.
  func iStartsWith(a, b: openArray[char], start=0): bool =  
    ## b must be in lower case
    if b.len > a.len - start: return false
    result = true
    for i, c in b:
      if a[i+start].toLowerAscii != c:
        return false
  func `~=`(a, b: openArray[char]): bool =
    ## b must be in lower case
    if a.len != b.len:
      return false
    a.iStartsWith b
  var negate = false
  let first = ori_s[0]
  result =
    if first == '-': negate = true; 1
    elif first == '+': 1
    else: 0

  template curIStart(s): bool =
    ori_s.iStartsWith(s, result)
  if curIStart "inf":
    result.inc 3
    if curIStart "inity":
      result.inc 5
    res = if negate: NegInf else: Inf
  elif curIStart "nan":
    result.inc 3
    res = if negate: -abs(NaN) else: abs(NaN)
  else:
    result = 0

func parse_inf_or_nan*(res: var float, ori_s: openArray[char]): bool =
  ## returns if successfully parses
  ## returns false when there are chars left after parsed in `ori_s`
  ##
  ## XXX: don't use parseFloat in std/strutils currently as it does not
  ## respect sign bit of `NaN`s.
  let le = ori_s.len
  le != 0 and le == ori_s.parse_inf_or_nan res
