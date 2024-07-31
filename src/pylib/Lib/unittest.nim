## Lib/unittest
##
## .. hint:: Currently `self: TestCase` in all functions is only a placeholder,
##   the actual implementation just replies the std/unittest.
##

import std/unittest
import std/macros

type
  TestCase* = ref object of RootObj

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

template assertRaises*(typ: typedesc, cb: typed, va: varargs[untyped]){.genSelf.} =
  bind expect
  expect typ:
    when compiles((let _ = cb(va))): discard cb(va)
    else: cb(va)

template assertIs*[T](a, b: T){.genSelf.} =
  bind check
  when T is (pointer|ptr|ref|proc|iterator):
    check a == b
  elif a is static or b is static:
    check a == b
  else:
    check a.addr == b.addr

