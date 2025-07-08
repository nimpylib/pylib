discard """
  targets: "c js"
"""
import pylib/pystring
import pylib/pybytes
import pylib/builtins/dict

from std/strutils import `%`  # test if causing conflict
discard "$#" % "asd"

import std/unittest

suite "percent format":
  test "with one non-tuple non-mapping arg":
    let one = 1.0  # test non-const
    check:
      b"Here is %b." % b"Night Raid" == b"Here is Night Raid."

      u"%f" % one == "1.000000"
      u"%g" % 1e60 == "1e+60"

  test "using flags":
    check:
      u"^%-3s$" % "a" == "^a  $"
      u"^%2s$" % "v" == "^ v$"

      u"%3u" % 1u == "  1"

      u"%+ d" % 1 == "+1"  # '+' takes precedence over ' '

  test "with mapping":
    check:
      u"4%(key)s6" % dict(key=8, unused=1) == "486"
      (u"%(name)s's hair is %(hair)s" % dict(name="Akame", hair="black") ==
        "Akame's hair is black")

  test "with tuple literal":
    check:
      u"%d guards %s." % (486, "EMT") == "486 guards EMT."
      u"%c%f" % ("C", 4) == "C4.000000"
      u"%c%f" % (67, 4) == "C4.000000"

    proc checkEvalOnce[T](x: T) =
      var cnt = 0
      proc shallCalledOnce(): T =
        inc cnt
        x

      check:
        u"^%d - %d." % (shallCalledOnce(), 555) == "^" & $x.int & " - 555."
        cnt == 1

    checkEvalOnce 3
    checkEvalOnce 3.5

  test "with tuple variable":
    block letTuple:
      let t = (97,5)
      check u"%c%f" % t == "a5.000000"

    block varTuple:
      var t = (97,5)
      check u"%c%f" % t == "a5.000000"
  #test "with tuple variable using flags":

  test "%s %a %r for non-string":
    check:
      u"%s" % 1 == "1"
      u"%s" % [1] == "[1]"
      u"%r" % 1.0 == "'1.0'"

