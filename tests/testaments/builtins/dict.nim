
import pylib/builtins
import std/unittest

test "dict":
  var d = dict(k=1)
  var dd = d.copy()
  check d["k"] == 1

  d.update(k=3)
  d.update([("k2", 2)])

  check len(d) == 2

  check len(dd) == 1

  # XXX: the following cannot run if included in ../../tester.nim
  # why?
  check str(dict([(1,2)])) == str("{1: 2}")

test "dict views":
  let
    d = dict(a=1)
    v = d.values()  # not compile before 0.9.12

  check 1 in v
