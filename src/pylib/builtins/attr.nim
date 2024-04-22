
import std/macros

proc newDotExpr(x: NimNode, attr: string): NimNode =
  newDotExpr(x, ident attr)

macro hasattr*(x; attr: static[string]): bool =
  let dot = newDotExpr(x, attr)
  newCall("compiles", dot)

macro getattr*(x; attr: static[string]): untyped =
  newDotExpr(x, attr)

macro getattr*(x; attr: static[string], default): untyped =
  let val = newDotExpr(x, attr)
  let attrS = newLit attr
  result = quote do:
    when not hasattr(`x`, `attrS`): `default`
    else: `val`

macro setattr*(x; attr: static[string], val) =
  newAssignment(newDotExpr(x, attr), val)

