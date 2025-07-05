discard """
  targets: "c js"
"""
import pylib/pystring
import pylib/pybytes
import pylib/builtins/dict

from std/strutils import `%`  # test if causing conflict
discard "$#" % "asd"

import std/unittest

test "percent format with one arg":
  let one = 1.0  # test non-const
  check:
    b"Here is %b." % b"Night Raid" == b"Here is Night Raid."

    u"^%-3s$" % "a" == "^a  $"
    u"^%2s$" % "v" == "^ v$"


    u"%3u" % 1u == "  1"
    u"%f" % one == "1.000000"
    u"%r" % one == "'1.0'"
    u"%g" % 1e60 == "1e+60"

    u"%+ d" % 1 == "+1"  # '+' takes precedence over ' '

test "percent format with mapping":
  check:
    u"1%(key)s2" % dict(key=3, unused=1) == "132"
    (u"%(name)s's hair is %(hair)s" % dict(name="Akame", hair="black") ==
      "Akame's hair is black")


when not defined(js): # As of Nim2.3.1, JS lacks it
 test "percent format with multiply args":
  check:
    u"%s is %d." % ("A", 555) == "A is 555."
    u"%c%f" % ("c", 4) == "c4.000000"
    u"%c%f" % (65, 4) == "A4.000000"

