
import std/macros
import ../iter_next

import ./macroutils

proc mapIterBodyImpl*(f: NimNode #[proc]#,
    iterables: NimNode #[varargs[typed]#): NimNode =


  let
    n = iterables.len
    rng = 0..<n
  result = newStmtList()

  let iters = genSym(nskLet, "iters")
  var
    itersVal = newTuple()
    resType = newTuple()
  for i in iterables:
    let it = newCall(bindSym"iter", i)
    itersVal.add it
    resType.add newCall("typeof", newCall(bindSym"next", it))
  result.add newLetStmt(iters, itersVal)


  let res = genSym(nskVar, "res")
  result.add noInitVarDecl(res, resType)

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
  
