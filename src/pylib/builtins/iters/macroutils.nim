
import std/macros
import ../iter_next
export iter_next.iter

func newTuple*: NimNode = newNimNode nnkTupleConstr
let emptyn*{.compileTime.} = newEmptyNode()


func noInitVarDecl*(name, Type: NimNode): NimNode =
  quote do:
    var `name`{.noInit.}: `Type`

const preferredGenIterResName*{.strdefine.} = "gen_iter_res"

proc addResDecl*(body: NimNode; iterables: NimNode|seq[NimNode];
    res = ident preferredGenIterResName,
    iters = genSym(nskLet, "iters")): NimNode{.discardable.} =
  ## returns res type (a tuple)
  var
    itersVal = newTuple()
    resType = newTuple()
  for i in iterables:
    let it = newCall("iter", i)
    itersVal.add it
    resType.add newCall("typeof", newCall("next", it))
  body.add newLetStmt(iters, itersVal)

  body.add noInitVarDecl(res, resType)

  return resType

func newLoop*(body: NimNode): NimNode =
  nnkWhileStmt.newTree newLit(true), body

proc newNullaryLambdaIter*(body: NimNode; resType = ident"auto"): NimNode =
  newProc(emptyn, [resType], body, nnkIteratorDef)

type PreBreakCb* = proc (i: NimNode): NimNode{.closure.}

proc noopPreBreakCb(_: NimNode): NimNode = emptyn

proc addEachIter*(loopBody: NimNode; nIt: int; itors, res: NimNode;
    preBreakCb: PreBreakCb = noopPreBreakCb) =
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


proc addLoopEach*(loopBody: NimNode, parent: NimNode; iterables: NimNode|seq[NimNode];
    res = ident preferredGenIterResName;
    preBreakCb: PreBreakCb = noopPreBreakCb): NimNode{.discardable.} =
  ## returns res type (a tuple)
  let
    n = iterables.len
    iters = genSym(nskLet, "iters")

  result = parent.addResDecl(iterables, res, iters=iters)

  loopBody.addEachIter n, iters, res, preBreakCb

