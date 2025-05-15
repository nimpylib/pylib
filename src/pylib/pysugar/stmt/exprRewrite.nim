
import std/macros
import std/macrocache
from std/strutils import toLowerAscii, normalize
import ../../pystring/[strimpl, strprefix]
import ../../builtins/[list_decl, set, dict, pyslice]
import ./frame

const CollectionSyms = CacheSeq"CollectionSyms"
static:
  CollectionSyms.add bindSym"list"
  CollectionSyms.add bindSym"pyset"
  CollectionSyms.add bindSym"toPyDict"
  CollectionSyms.add bindSym"slice"

using e: NimNode
using mparser: var PyAsgnRewriter
proc toPyExpr*(mparser; atm: NimNode): NimNode

template newSlice(a, b: NimNode): NimNode =
  newCall(CollectionSyms[3], a, b)

proc colonToSlice(mparser; colonExpr: NimNode): NimNode =
  ## a:b -> slice(a,b)
  newSlice(mparser.toPyExpr colonExpr[0], mparser.toPyExpr colonExpr[1])

proc rewriteSliceInBracket(mparser; bracketExpr: NimNode): NimNode =
  result = bracketExpr.copyNimNode
  result.add mparser.toPyExpr bracketExpr[0]
  for i in 1..<bracketExpr.len:
    let ele = bracketExpr[i]
    result.add:
      let k = ele.kind
      if k == nnkExprColonExpr: mparser.colonToSlice ele
      elif k == nnkInfix and ele[0].eqIdent":-": # like `ls[1:-1]`
        newSlice(mparser.toPyExpr ele[1], prefix(mparser.toPyExpr ele[2], "-"))
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
    actStr.toLowerAscii in ["f", "fr", "rf",  "b", "br", "rb",  "u"]
    # no need to worry "r"
  when defined(nimpylibStrlitCatAllowStrformat):
    trueIf k == nnkPrefix and
      actStr == "&"
    trueIf k == nnkCallStrLit and
      actStr.normalize == "fmt"


proc rewriteStrLitCat(mparser; e: NimNode): NimNode =
  if e.len != 2:
    return e
  let
    lhs = e[0]
    rhs = e[1]
  if not lhs.validStrLit: return e
  result = infix(mparser.toPyExpr lhs, "&", mparser.toPyExpr rhs)

func toStr(e): NimNode =
  result = nnkCallStrLit.newTree(bindSym"u", e)
  ## NOTE: u"xxx" does perform `translateEscape`

template asisIfEmpty(e) =
  if e.len == 0: return e

func getTypeof(e: NimNode): NimNode =
  newCall("typeof", e)

proc rewriteEachEle(mparser; e: NimNode; bracketNode = nnkBracket): NimNode =
  result = newNimNode bracketNode
  for i in e:
    result.add mparser.toPyExpr i

template mapEleCall(mparser;
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
  let res = mparser.rewriteEachEle(e, bracketNode)
  let eleTyp = getTypeof res[0]
  newCall(
    nnkBracketExpr.newTree(
      initCall,
      eleTyp
    ), res
  )


proc toList(mparser; e): NimNode = mparser.mapEleCall(CollectionSyms[0], e)
proc toSet (mparser; e): NimNode = mparser.mapEleCall(CollectionSyms[1], e)
proc toDict(mparser; e): NimNode =
  e.asisIfEmpty

  var eles = e.copyNimNode
  for i in e:
    var n = i.copyNimNode
    n.add i[0].toStr
    n.add mparser.toPyExpr i[1]
    eles.add n

  let
    ele = eles[0]
    eleVal = ele[1]
    eleValTyp = getTypeof eleVal

  newCall(
    nnkBracketExpr.newTree(
      CollectionSyms[2],
      bindSym"PyStr",
      eleValTyp
    ), eles
  )
proc toTuple(mparser; e): NimNode =
  result = newNimNode nnkTupleConstr
  for i in e:
    result.add mparser.toPyExpr i

proc rewriteEqualMinus(mparser; e; k=nnkAsgn): NimNode =
  ## x==-1 -> x == -1
  ## x=-1 -> x = -1
  
  let lhs = mparser.toPyExpr e[1]
  template rhs: NimNode = newCall("-", mparser.toPyExpr e[2])
  if e[0].eqIdent"=-":
    k.newTree lhs, rhs
  elif e[0].eqIdent"==-":
    newCall "==", lhs, rhs
  else: e

proc callToPyExpr*(mparser; e): NimNode

template toPyExprImpl(mparser; atm: NimNode; toListCb; equalMinusAs=nnkAsgn): NimNode =
  case atm.kind
  of nnkExprEqExpr:
    nnkExprEqExpr.newTree(atm[0], mparser.toPyExpr atm[1])
  of nnkBracketExpr:
    mparser.rewriteSliceInBracket atm
  of nnkCommand:
    mparser.rewriteStrLitCat atm
  of nnkCall:
    mparser.callToPyExpr atm
  of nnkPrefix:
    nnkPrefix.newTree atm[0], mparser.toPyExpr atm[1]
  of nnkPar:
    nnkPar.newTree mparser.toPyExpr atm[0]
  of nnkInfix:
    mparser.rewriteEqualMinus atm, equalMinusAs

  of nnkTripleStrLit,
      nnkStrLit, nnkRStrLit:
    atm.toStr
  #of nnkCallStrLit:
  # NOTE: f"xxx" does perform `translateEscape`
  #  so we don't perform translation here

  of nnkBracket:    mparser.toListCb atm
  of nnkCurly:      mparser.toSet    atm
  of nnkTableConstr:mparser.toDict   atm
  of nnkTupleConstr:mparser.toTuple  atm
  else:
    atm

proc toPyExpr*(mparser; atm: NimNode): NimNode = mparser.toPyExprImpl atm, toList
proc toPyExprNoList*(mparser; atm: NimNode): NimNode = mparser.toPyExprImpl atm, rewriteEachEle

proc argInCallToPyExpr(mparser; atm: NimNode): NimNode =
  ## f(x=-1) needs to be rewritten as Call(ExprEqExpr(Ident"x", -1))
  mparser.toPyExprImpl atm, toList, nnkExprEqExpr

proc preNew(n: NimNode): NimNode =
  ident("new" & n.strVal)

proc callToPyExpr*(mparser; e): NimNode =
  ## In addition, it will rewrite `cls(xxx)` to `newCls(xxx)`
  let callee = e[0]
  template addArg(addArgCb) =
    for i in 1..<e.len:
      let arg{.inject.} = mparser.argInCallToPyExpr e[i]
      addArgCb
  template retAfterAddOriCall =
    addArg:
      oriCall.add arg
    return oriCall
    
  var
    newCls: NimNode
    oriCall = newCall callee
  case callee.kind
  of nnkIdent: newCls = callee.preNew
  of nnkDotExpr:
    if callee[1].len == 0:
      var lhs = callee[0]
      # in case `module.cls`
      newCls = newDotExpr(lhs, callee[1].preNew)
      while true:
        if lhs.eqIdent"self":
          # assume no module named self
          retAfterAddOriCall
        elif lhs.len == 0:
          break
        elif lhs.kind != nnkDotExpr or lhs[1].kind != nnkIdent:
          retAfterAddOriCall
        lhs = lhs[0]
    else:
      retAfterAddOriCall
  else:
    retAfterAddOriCall
  var newClsCall = newCall newCls
  addArg:
    oriCall.add arg
    newClsCall.add arg
  result = quote do:
    when declared(`newCls`) and declared(`callee`) and compiles(`newClsCall`):
      `newClsCall`
    else:
      `oriCall`

