## Lib/unittest
##
## .. hint:: Currently `self: TestCase` in all functions is only a placeholder,
##   the actual implementation just replies the std/unittest.
##

import std/unittest
import std/macros
from ../../pyerrors/simperr import TypeError
export TypeError

import ./case_py/[
  types,
  util,
  prc_main,
  prc_cleanup,
  meth,
]
export types, meth, prc_main, prc_cleanup

template gen1(name, op){.dirty.} =
  bind check
  template name*(a){.genSelf.} =
    check op(a)

template asis[T](a: T): T = a
template gen1(name){.dirty.} =
  gen1 name, asis

template gen2(name, op){.dirty.} =
  bind check
  template name*(a, b){.genSelf.} =
    check op(a, b)

export fail
template fail*(self: TestCase) =
  bind fail
  fail()

template fail*(msg: string){.genSelf.} =
  bind fail, checkpoint
  checkpoint msg
  fail()

gen1 assertFalse, `not`
gen1 assertTrue

template assertRaises*(typ: typedesc, cb: typed, va: varargs[untyped]){.genSelf.} =
  bind expect
  expect typ:
    when compiles((let _ = cb(va))): discard cb(va)
    else: cb(va)

template assertRaises*(typ: typedesc[TypeError], cb: typed, va: varargs[untyped]){.genSelf.} =
  bind expect
  when compiles((let _ = cb(va))):
    expect typ: discard cb(va)
  elif compiles(cb(va)):
    expect typ: cb(va)
  else:
    discard  ## "not compile" is seen as Compile-time TypeError

gen2 assertEqual, `==`
gen2 assertNotEqual, `!=`

gen2 assertIn, `in`
gen2 assertNotIn, `not_in`

template assertIsOrNotIs[T](a, b: T; op){.genSelf.} =
  bind check
  when T is (pointer|ptr|ref|proc|iterator):
    check a op b
  elif a is static or b is static:
    check a op b
  else:
    check a.addr op b.addr

template assertIs*[T](a, b: T){.genSelf.} =
  bind assertIsOrNotIs
  assertIsOrNotIs(a, b, `==`)

template assertIsNot*[T](a, b: T){.genSelf.} =
  bind assertIsOrNotIs
  assertIsOrNotIs(a, b, `!=`)

gen2 assertLess, `<`
gen2 assertLessEqual, `<=`
gen2 assertGreater, `>`
gen2 assertGreaterEqual, `>=`

gen2 assertIsInstance, `is`
gen2 assertNotIsInstance, `is_not`

func fmtSkip(name, reason: string): string = name & ": " & reason

template skipTest*(reason: string){.genSelf.} =
  bind skip, fmtSkip
  const msg = fmtSkip(astToStr(self), reason)
  when declared(testSuiteName):
    testSuiteName = msg
  else:
    checkpoint msg
  ## XXX: TODO: not really python-like
  skip()

proc skipTest(testStmt, reason: NimNode): NimNode =
  expectKind testStmt, nnkCommand
  result = newNimNode nnkCommand
  result.add testStmt[0]
  let name = testStmt[1]
  result.add newCall(bindSym"fmtSkip", name, reason)
  result.add newStmtList(
    newCall(bindSym"skip")
  )

template skip*(reason; body) =
  ## EXT.
  bind skipTest
  skipTest(body, reason)

template skip*(reason: string): untyped =
  bind skip, fmtSkip
  template temp(p: proc) =
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
      elseBody.add skipTest(s, reason)
  elif body.kind == nnkCommand and body[0].eqIdent "test":
    # test "xxx"
    elseBody.add skipTest(body, reason)
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
