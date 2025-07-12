discard """
  targets: "c js"
  matrix: ";-d:pylibUseFormatValue"
"""
import pylib/pystring

import pylib/builtins/dict

import std/unittest

import std/tables

suite "str.format_map":
  test "dict":
    let d = dict(
      aa3=12
    )
    check "^12$" == u"^{aa3}$".format_map(d)

  test "table":
    check "^13$" == u"^{abc}$".format_map({"abc": 13}.toTable)

  test "map is only evaluated once":
    var c = 0
    proc f: Table[string, int] =
      inc c
      {"abc": 13, "cb": 2}.toTable
    check "^13_2$" == u"^{abc}_{cb}$".format_map(f())
    check c == 1

suite "str.format":
  test "non-static format string":
    let aa = 'c'
    var vs = u"{},"
    assert "5,c" == (vs + "{}").format(3+2, aa)
    vs += "}}"
    assert "5,}}c" == (vs + "{}").format(5, aa)
    assert "5,}}4" == (vs + "{aa}").format(5, aa=4)
  #test "compile-time":
  # it is checked at `when isMainModule` of stringlib/format.nim
