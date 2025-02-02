
import std/macros
import ../iter_next

import ./macroutils

proc mapIterBodyImpl*(f: NimNode #[proc]#,
    iterables: NimNode #[varargs[typed]#,
    res = genSym(nskVar, "res")): NimNode =
  ## `res`: generated symbol name temporarily storing iteration result
  ##   and will be used as if `f(*res)` in Python at each loop;
  ##   do not use `genSym` if wanting simpler err msg for arg num mismatch
  let
    n = iterables.len
    rng = 0..<n
  result = newStmtList()

  let iters = genSym(nskLet, "iters")
  result.addResDecl(iterables, res, iters=iters)

  var loopBody = newStmtList()

  loopBody.addEachIter n, iters, res

  var callFunc = newCall(f)
  for i in rng:
    let iNode = newLit i
    callFunc.add nnkBracketExpr.newTree(res, iNode)

  loopBody.addYield callFunc
  ##[
   while true:
     `loop each iterators`
     yield `res`
  ]##

  result.add newLoop loopBody

  result = newNullaryLambdaIter result

  #echo result.repr
  
