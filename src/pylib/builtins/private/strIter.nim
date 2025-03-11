
# as strimpl export len(c: char),
# we use another name to prevent `Error: ambiguous call`
template calLen(cs: char): int = 1
template calLen(cs: string): int = cs.len

template strIterImpl*(it; strProc;
    start, stop: char|string; linear = false): string =
  ## requires `iter(it)` and `it.len`
  bind calLen
  let le = it.len
  var result = newStringOfCap(calLen(start) + 3*le + calLen(stop) - 2)
  result.add start
  when linear:
    result.add start
    result.add ls[0].strProc
    for i in 1..<le:
      result.add ", "
      result.add ls[i].strProc
  else:
    var notFirst = false
    for k in iter(it):
      if likely notFirst:
        result.add ", "
      result.add:
        when compiles(strProc(it, k)): strProc(it, k)
        else: strProc(k)
      notFirst = true
  result.add stop
  result

template genDollarRepr*(Coll; start, stop: char|string;
    strProc; linear = false){.dirty.} =
  bind strIterImpl
  template repr*(self: Coll): string{.dirty.} =
    bind strIterImpl
    mixin repr
    strIterImpl self, strProc, start, stop, linear

  template `$`*(self: Coll): string =
    bind repr
    repr self

template genDollarRepr*(Coll; start, stop: char|string;
    linear = false){.dirty.} =
  mixin repr
  genDollarRepr(Coll, start, stop,
    repr, false)
