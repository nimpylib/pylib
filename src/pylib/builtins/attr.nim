
import std/macros
import ../pystring/strimpl
import ../Lib/sys_impl/auditImpl/macrohelper

proc newDotExpr(x: NimNode, attr: string): NimNode =
  newDotExpr(x, ident attr)

template gen(S){.dirty.} =
  macro hasattr*(x; attr: static[S]): bool =
    let dot = newDotExpr(x, attr)
    newCall("compiles", dot)
  
  macro getattr*(x; attr: static[S]): untyped =
    result = newStmtWithAudit(
      "object.__getattr__",  # sys.audit("object.__getattr__", attr)
      attr.newLit)
    result.add newDotExpr(x, attr)
  
  macro getattr*(x; attr: static[S], default): untyped =
    result = newStmtWithAudit(
      "object.__getattr__",  # sys.audit("object.__getattr__", attr)
      attr.newLit)
    let val = newDotExpr(x, attr)
    let attrS = newLit attr
    result.add quote do:
      when not hasattr(`x`, `attrS`): `default`
      else: `val`
  
  macro setattr*(x; attr: static[S], val) =
    result = newStmtWithAudit(
      "object.__setattr__",  # sys.audit("object.__setattr__", attr, val)
      attr.newLit, val)
    result.add newAssignment(newDotExpr(x, attr), val)
  
gen string
gen PyStr

