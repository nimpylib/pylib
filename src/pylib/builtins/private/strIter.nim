
# as strimpl export len(c: char),
# we use another name to prevent `Error: ambiguous call`
template calLen(cs: char): int = 1
template calLen(cs: string): int = cs.len

template strIterImpl*(it: typed{atom}; strProc;
    start, stop: char|string; linear = false; useIter = true): string =
  ## requires `iter(it)`, `it.len`, `it[int]`
  bind calLen
  let le = it.len
  var result = newStringOfCap(calLen(start) + 3*le + calLen(stop) - 2)
  result.add start
  when linear:
    if le != 0:
      result.add it[0].strProc
      for i in 1..<le:
        result.add ", "
        result.add it[i].strProc
  else:
    var notFirst = false
    for k in (when useIter: iter(it) else: items(it)):
      if likely notFirst:
        result.add ", "
      result.add:
        when compiles(strProc(it, k)): strProc(it, k)
        else: strProc(k)
      notFirst = true
  result.add stop
  result

template strIterImpl*(itExpr: typed{~atom}; strProc;
    start, stop: char|string; linear = false; useIter = true): string =
  bind strIterImpl
  let it = itExpr
  strIterImpl(it, strProc, start, stop, linear, useIter)

template gen(name; strProcType){.dirty.} =
  template name(Coll; start, stop: char|string;
      strProc: strProcType; linear = false; useIter = true){.dirty.} =
    bind strIterImpl
    template repr*(self: Coll): string{.dirty.} =
      bind strIterImpl
      strIterImpl self, strProc, start, stop, linear, useIter

    template `$`*(self: Coll): string =
      bind repr
      repr self

gen genDollarRepr, typed
gen genDollarReprAux, untyped

template genDollarRepr(Coll; start, stop: char|string;
    linear = false; useIter = true){.dirty.} =
  bind genDollarReprAux
  genDollarReprAux(Coll, start, stop,
    repr, linear, useIter)

export genDollarRepr
