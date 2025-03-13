## Currently we just use `system.tuple` for Python's tuple

import std/macros

macro items*(t: tuple): untyped =
  result = newNimNode nnkBracket
  if t.len != 0:
    for i in t:
      result.add i
  else:
    let nElem = t.getTypeImpl.len
    if nElem == 0:
      return parseExpr(
        "items(array[0, int]([]))"
      ) # any type shall be ok
    for i in 0..<nElem:
      result.add nnkBracketExpr.newTree(t, newLit i)
  result = newCall(ident"items", result)

macro len*(t: tuple): int = newLit t.len

when defined(js):
  import ./private/strIter
  # XXX: NIM-BUG: as of 2.3.1, `repr (1,)` -> "[Field0 = 1]" when JS
  genDollarRepr tuple, '(', ')', useIter=false

when isMainModule:
  # not compile:
  #for i in (1, 2.0): echo i

  for i in (): echo i

  for i in (1, 2): echo i
  let t = (1, 2)
  for i in t:
    echo i
