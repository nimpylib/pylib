
import std/macros
import ../iter_next

func newTuple*: NimNode = newNimNode nnkTupleConstr
let emptyn*{.compileTime.} = newEmptyNode()


func noInitVarDecl*(name, Type: NimNode): NimNode =
  quote do:
    var `name`{.noInit.}: `Type`

const preferredGenIterResName*{.strdefine.} = "gen_iter_res"

func addResDecl*(body: NimNode; iterable: NimNode;
    res = ident preferredGenIterResName,
    iters = genSym(nskLet, "iters")): NimNode{.discardable.} =
  ## returns res type (a tuple)
  var
    itersVal = newTuple()
    resType = newTuple()
  for i in iterable:
    let it = newCall(bindSym"iter", i)
    itersVal.add it
    resType.add newCall("typeof", newCall(bindSym"next", it))
  body.add newLetStmt(iters, itersVal)

  body.add noInitVarDecl(res, resType)

  return resType

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
