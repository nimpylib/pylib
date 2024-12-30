
import std/macros


proc toPyExpr*(atm: NimNode): NimNode

proc colonToSlice*(colonExpr: NimNode): NimNode =
  ## a:b -> slice(a,b)
  colonExpr.expectKind nnkExprColonExpr
  newCall(ident"slice", colonExpr[0].toPyExpr, colonExpr[1].toPyExpr)

proc toSliceInBracket(bracketExpr: NimNode): NimNode =
  result = bracketExpr.copyNimNode
  result.add bracketExpr[0].toPyExpr
  result.add colonToSlice bracketExpr[1]

proc toPyExpr*(atm: NimNode): NimNode =
  case atm.kind
  of nnkBracketExpr:
    toSliceInBracket atm
  else:
    atm
