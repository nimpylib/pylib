
# as strimpl export len(c: char),
# we use another name to prevent `Error: ambiguous call`
template calLen(cs: char): int = 1
template calLen(cs: string): int = cs.len

template strIterImpl*(it; strProc;
    start, stop): string =
  ## requires `iter(it)` and `it.len`
  bind calLen
  let le = it.len
  var result = newStringOfCap(calLen(start) + 3*le + calLen(stop))
  result.add start
  var notFirst = false
  for k in iter(it):
    if likely notFirst:
      result.add ", "
    result.add strProc(k)
    notFirst = true
  result.add stop
  result
