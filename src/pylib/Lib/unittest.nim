## Lib/unittest
##
## .. hint:: Currently `self: TestCase` in all functions is only a placeholder,
##   the actual implementation just replies the std/unittest.
##

import std/unittest
import std/macros
from ../pyerrors/simperr import TypeError
export TypeError

type
  TestCase* = ref object of RootObj

func newTestCase*: TestCase = TestCase()


macro genSelf(templ) =
  result = newStmtList()
  result.add templ
  var nTempl = copyNimTree templ
  nTempl.params.insert 1, newIdentDefs(ident"self", bindSym"TestCase")
  result.add nTempl

template assertEqual*(a, b){.genSelf.} =
  bind check
  check a == b
template assertNotEqual*(a, b){.genSelf.} =
  bind check
  check a != b
template assertTrue*(bo){.genSelf.} =
  bind check
  check bo

template assertFalse*(bo){.genSelf.} =
  bind check
  check not bo

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

template assertIs*[T](a, b: T){.genSelf.} =
  bind check
  when T is (pointer|ptr|ref|proc|iterator):
    check a == b
  elif a is static or b is static:
    check a == b
  else:
    check a.addr == b.addr

template addSkip(reason) = checkpoint reason  ##\
## XXX: TODO: not really python-like

template skip*(reason; body) =
  ## EXT.
  addSkip reason

template skip*(reason: string): untyped =
  addSkip reason
  proc (_: proc) = discard

proc asis_id[P: proc](x: P): P = x

template skipIf*(condition: bool, reason: string) =
  bind asis_id, skip
  if condition:
      return skip(reason)
  return asis_id

template skipIf*(condition: bool, reason: string; body) =
  addSkip reason
  if not condition:
    body

template skipUnless*(condition: bool, reason: string) =
  bind skipIf
  skipIf(not condition, reason)

template skipUnless*(condition: bool, reason: string; body) =
  bind skipIf
  skipIf(not condition, reason, body)
