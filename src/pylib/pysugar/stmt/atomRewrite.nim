
import std/macros


proc toPyExpr*(atm: NimNode): NimNode

proc colonToSlice(colonExpr: NimNode): NimNode =
  ## a:b -> slice(a,b)
  newCall(ident"slice", colonExpr[0].toPyExpr, colonExpr[1].toPyExpr)

proc rewriteSliceInBracket(bracketExpr: NimNode): NimNode =
  result = bracketExpr.copyNimNode
  result.add bracketExpr[0].toPyExpr
  for i in 1..<bracketExpr.len:
    result.add:
      let ele = bracketExpr[i]
      if ele.kind == nnkExprColonExpr: colonToSlice ele
      else: ele

proc toPyExpr*(atm: NimNode): NimNode =
  case atm.kind
  of nnkBracketExpr:
    rewriteSliceInBracket atm
  else:
    atm
