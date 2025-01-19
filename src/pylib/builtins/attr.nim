
import std/macros
import ../pystring/strimpl

proc newDotExpr(x: NimNode, attr: string): NimNode =
  newDotExpr(x, ident attr)

template gen(S){.dirty.} =
  macro hasattr*(x; attr: static[S]): bool =
    let dot = newDotExpr(x, attr)
    newCall("compiles", dot)
  
  macro getattr*(x; attr: static[S]): untyped =
    newDotExpr(x, attr)
  
  macro getattr*(x; attr: static[S], default): untyped =
    let val = newDotExpr(x, attr)
    let attrS = newLit attr
    result = quote do:
      when not hasattr(`x`, `attrS`): `default`
      else: `val`
  
  macro setattr*(x; attr: static[S], val) =
    newAssignment(newDotExpr(x, attr), val)
  
gen string
gen PyStr

