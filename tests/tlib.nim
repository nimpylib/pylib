# XXX: While the coverage is rather low,
#  considering many `Lib` of nimpylib are mostly wrapper around Nim's stdlib,
#  we shall mainly focus on the cases where Python differs Nim,
#  and leave the rest to Nim's own stdlib test.

import std/macros

import pylib/Lib/[random, string]

test "random":
  # TODO: more test (maybe firstly set `seed`)
  check randint(1,2) in 1..2

test "Lib/string":
  check "hello δδ".capwords == "Hello Δδ" ## support Unicode
  check "01234".capwords == "01234"

  let templ = Template("$who likes $what")
  check templ.substitute(who="tim", what="kung pao") == "tim likes kung pao"
  
  expect ValueError:
    let d = dict(who="tim")
    discard templ.substitute(d)

const
  SourceDir = currentSourcePath().parentDir
  LibTestMain = SourceDir /../ "src/pylib/Lib/test/main.nim"
macro importTestLibMain =
  result = nnkImportStmt.newTree newLit LibTestMain

importTestLibMain()
testAll()

