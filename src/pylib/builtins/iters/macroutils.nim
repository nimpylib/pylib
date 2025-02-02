
import std/macros
import ../iter_next

func newTuple*: NimNode = newNimNode nnkTupleConstr
let emptyn*{.compileTime.} = newEmptyNode()
func noInitVarDecl*(name, Type: NimNode): NimNode =
  quote do:
    var `name`{.noInit.}: `Type`

func newLoop*(body: NimNode): NimNode =
  nnkWhileStmt.newTree newLit(true), body

proc newNullaryLambdaIter*(body: NimNode; resType = ident"auto"): NimNode =
  newProc(emptyn, [resType], body, nnkIteratorDef)


proc noopPreBreakCb(_: NimNode): NimNode = emptyn

proc addEachIter*(loopBody: NimNode; nIt: int; itors, res: NimNode; preBreakCb = noopPreBreakCb) =
  let nextImplId = bindSym"nextImpl"
  for iVal in 0..<nIt:
    let
      i = newLit iVal
      preBreak = preBreakCb i
    loopBody.add quote do:
      if not `nextImplId`(`itors`[`i`], `res`[`i`]):
        `preBreak`
        break

proc addYield*(res, dest: NimNode) =
  res.add nnkYieldStmt.newTree dest
