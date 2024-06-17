## modified from std/strutils, adding `count` param
# and refine some style, add some opt, reduce code size by template.

import std/strutils

func replace*(s: string, sub, by: char, count: Natural): string =
  result = newString(s.len)
  var i = 0
  var nDone = 0
  while i < s.len:
    if nDone == count:
      # copy the rest:
      result.setLen i  # as result was of `s.len`
      result.add substr(s, i)
      break
    if s[i] == sub:
      result[i] = by
      nDone.inc
    else: result[i] = s[i]
    inc(i)

func replace*(s: string, sub, by: string, count: Natural): string =
  ## count must be Natural
  let subLen = sub.len
  if subLen == 0: return s

  template replaceImpl(findCb) =
    let last = s.high
    var
      nDone = 0
      i = 0
    while nDone != count:
      let j = findCb(i, last)
      if j < 0: break
      result.add substr(s, i, j - 1)
      result.add by
      nDone.inc
      i = j + subLen
    # copy the rest:
    result.add substr(s, i)
  
  if subLen == 1:
    # when the pattern is a single char, we use a faster
    # char-based search that doesn't need a skip table:
    let c = sub[0]
    if by.len == 1:
      return s.replace(c, by[0], count)
    template findChar(first, last: int): int =
      s.find(c, first, last)
    replaceImpl(findChar)
  else:
    var a = initSkipTable(sub)
    template findWithTable(first, last: int): int =
      find(a, s, sub, first, last)
    replaceImpl(findWithTable)
