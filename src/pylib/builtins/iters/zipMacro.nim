
import std/macros
import ./macroutils

func raiseZipBound*(ordLonger: int){.inline.} =
  raise newException(ValueError, 
    "zip() argument " & $ordLonger & " is longer than argument " & $(ordLonger-1))


proc zipIterBodyImpl*(iterables: NimNode|seq[NimNode], strict: NimNode
    ): NimNode =

  let res = genSym(nskVar, "res")

  result = newStmtList()

  let raiseBound = bindSym"raiseZipBound"
  proc checkBound(i: NimNode): NimNode =
    newIfStmt( (strict, newCall(
      raiseBound, infix(i, "+", newLit(1))
    ) ))

  ## var itors = (iter(it1), iter(it2), ...)
  ## var res: (A, B,...)

  ##[
  # inline-loop each iterators
  ]##
  var itorsVal = newTuple()
  var loopBody = newStmtList()
  loopBody.addLoopEach(result, iterables, res, preBreakCb=checkBound)


  ##[
   while true:
     `loop each iterators`
     yield `res`
  ]##
  loopBody.addYield res

  result.add newLoop loopBody

  result = newNullaryLambdaIter(result)

  #echo result.repr
