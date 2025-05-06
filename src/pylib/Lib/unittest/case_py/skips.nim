import std/macros
import std/unittest
import ./[util, sig_exc]

func fmtSkip(name, reason: string): string = name & ": " & reason

template skipTest*(reason: string){.genSelf.} =
  bind skip, fmtSkip
  let msg = fmtSkip(astToStr(self), reason)
  checkpoint msg
  ## XXX: TODO: not really python-like
  raise newException(SkipTest, reason)

proc skipTest(reason, testStmt: NimNode): NimNode =
  if testStmt.kind == nnkCommand:
    result = newNimNode nnkCommand
    result.add testStmt[0]
    let name = testStmt[1]
    result.add newCall(bindSym"fmtSkip", name, reason)
    result.add newStmtList(
      newCall(bindSym"skip")
    )
  else:
    result = newCall(bindSym"skipTest", reason)

template skip*(reason; body) =
  ## EXT.
  bind skipTest
  skipTest(reason, body)

template skip*(reason: string): untyped =
  bind skip, fmtSkip
  proc temp(p: proc) =
    test fmtSkip(astToStr(p), reason):
      skip()
  temp

proc asis_id[P: proc](x: P): P = x

template skipIf*(condition: bool, reason: string): proc =
  bind asis_id, skip
  if condition: skip(reason)
  else: asis_id

macro makeSkip(cond: bool; reason: string; body; staticBanch: static[bool]) =
  result = newNimNode(if staticBanch: nnkWhenStmt else: nnkIfStmt)
  result.add nnkElifBranch.newTree(
    cond, body
  )
  var elseBody = newStmtList()
  if body.kind == nnkStmtList:
    for s in body:
      elseBody.add skipTest(reason, s)
  elif body.kind == nnkCommand and body[0].eqIdent "test":
    # test "xxx"
    elseBody.add skipTest(reason, body)
  result.add nnkElse.newTree elseBody

template doOrSkip(cond: bool; reason: string; body) =
  bind makeSkip
  makeSkip cond, reason, body, false
template doOrSkip(cond: static bool; reason: string; body) =
  bind makeSkip
  makeSkip cond, reason, body, true

template skipIf*(condition: bool, reason: string; body) =
  ## EXT.
  bind doOrSkip
  doOrSkip not condition, reason, body

template skipUnless*(condition: bool, reason: string): proc =
  bind skipIf
  skipIf(not condition, reason)

template skipUnless*(condition: bool, reason: string; body) =
  ## EXT.
  bind skipIf
  skipIf(not condition, reason, body)
