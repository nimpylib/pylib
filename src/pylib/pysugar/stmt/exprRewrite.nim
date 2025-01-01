
import std/macros
from std/strutils import toLowerAscii, normalize
import ../../pystring/[strimpl, strprefix]

using e: NimNode
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

func toStr(e): NimNode =
  result = nnkCallStrLit.newTree(bindSym"u", e)
  ## NOTE: u"xxx" does perform `translateEscape`

template asisIfEmpty(e) =
  if e.len == 0: return e

func getTypeof(e: NimNode): NimNode =
  newCall("typeof", e)

template mapEleCall(
  initCall, e: NimNode;
  bracketNode = nnkBracket,
  ): NimNode =
  #[
   XXX: we infer element type specially for PyComplex,
     because if leaving Nim to do it,
     PyComplex (which `= PyTComplex[float]`)
   will be infered just as PyTComplex.
     what's more, such a type is even not compatible
     with original `PyTComplex` type (a.k.a. being regarded as a new type)
  ]#
  e.asisIfEmpty
  var res = newNimNode bracketNode
  for i in e:
    res.add i.toPyExpr
  let eleTyp = getTypeof res[0]
  newCall(
    nnkBracketExpr.newTree(
      initCall,
      eleTyp
    ), res
  )


proc toList(e): NimNode = mapEleCall(ident"list", e)
proc toSet (e): NimNode = mapEleCall(ident"pyset", e)
proc toDict(e): NimNode =
  e.asisIfEmpty

  var eles = e.copyNimNode
  for i in e:
    var n = i.copyNimNode
    n.add i[0].toStr
    n.add i[1].toPyExpr
    eles.add n

  let
    ele = eles[0]
    eleVal = ele[1]
    eleValTyp = getTypeof eleVal

  newCall(
    nnkBracketExpr.newTree(
      ident"toPyDict",
      bindSym"PyStr",
      eleValTyp
    ), eles
  )


proc toPyExpr*(atm: NimNode): NimNode =
  case atm.kind
  of nnkBracketExpr:
    rewriteSliceInBracket atm
  of nnkCommand:
    rewriteStrLitCat atm

  of nnkTripleStrLit,
      nnkStrLit, nnkRStrLit:
    atm.toStr
  #of nnkCallStrLit:
  # NOTE: f"xxx" does perform `translateEscape`
  #  so we don't perform translation here

  of nnkBracket:    atm.toList
  of nnkCurly:      atm.toSet
  of nnkTableConstr:atm.toDict
  else:
    atm