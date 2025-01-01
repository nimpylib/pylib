
import std/macros
from std/strutils import toLowerAscii, normalize
import ../../translateEscape

proc toPyExpr*(atm: NimNode): NimNode

proc colonToSlice(colonExpr: NimNode): NimNode =
  ## a:b -> slice(a,b)
  newCall(ident"slice", colonExpr[0].toPyExpr, colonExpr[1].toPyExpr)

proc rewriteSliceInBracket(bracketExpr: NimNode): NimNode =
  result = bracketExpr.copyNimNode
  result.add bracketExpr[0].toPyExpr
  for i in 1..<bracketExpr.len:
    let ele = bracketExpr[i]
    result.add:
      if ele.kind == nnkExprColonExpr: colonToSlice ele
      else: ele

#[
## strlitCat

following can almostly make Python/C-like  come to Nim:
```Nim
{.experimental: "callOperator".}
template `()`(a, b: string): string = a & b
```

but too lenien.

Once you wanna limit it to only string literal, `string{lit}` may be used.

However, although enough to implementing C's strlitCat,
then what about Python's f-string?

they're supported in nimpylib via template/macros

So never be of `string{lit}`, nor `static[string]`

That's a strong reason why I choose implementing it only within `def`,
via rewriting:
]#

template isStrLit(e: NimNode): bool = e.kind in nnkStrLit..nnkTripleStrLit
func validStrLit(e: NimNode): bool =
  template trueIf(e) =
    if e: return true
  let k = e.kind
  trueIf e.len == 0 and e.isStrLit
  let actStr = e[0].strVal
  trueIf k == nnkCallStrLit and
    actStr.toLowerAscii in ["f", "fr", "rf"]
    # no need to worry "r"
  when defined(nimpylibStrlitCatAllowStrformat):
    trueIf k == nnkPrefix and
      actStr == "&"
    trueIf k == nnkCallStrLit and
      actStr.normalize == "fmt"


proc rewriteStrLitCat(e: NimNode): NimNode =
  if e.len != 2:
    return e
  let
    lhs = e[0]
    rhs = e[1]
  if not lhs.validStrLit: return e
  result = infix(lhs.toPyExpr, "&", rhs.toPyExpr)

template translateTripleStrLit(e: NimNode): NimNode =
  ##[
.. hint:: removePrefix "\p" is performed before this,
  so we just cannot distinguish the following two cases:

## 1
```Nim
"""
str"""
```

## 2
```Nim
"""str"""
```
  ]##
  newLit translateEscape e.strVal

proc toPyExpr*(atm: NimNode): NimNode =
  case atm.kind
  of nnkBracketExpr:
    rewriteSliceInBracket atm
  of nnkCommand:
    rewriteStrLitCat atm
  of nnkTripleStrLit:
    translateTripleStrLit atm
  else:
    atm
