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

const dunder_file = currentSourcePath()
when defined(js):
  from std/strutils import rfind
  func restrict_parentDir(s: string): string {.compileTime.}=
    var idx = s.rfind '/'
    if idx == -1: idx = s.rfind '\\' 
    assert idx != -1, "unreachable: not abs path from currentSourcePath()"
    debugEcho  s[0..<idx]
    s[0..<idx]
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    let sourceDir = dunder_file.restrict_parentDir
    sourceDir & "/../" & lastPart
  ## XXX: when JS and nimvm, parentDir and `/../` cannot work
else:
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    dunder_file.parentDir /../ lastPart
# NOTE: inSourceParentDir impl is dup in src/pylib/Lib/math_impl/patch/inWordUtilsMapper.nim

const LibTestMain = inSourceParentDir "src/pylib/Lib/test/main.nim"
macro importTestLibMain =
  result = nnkImportStmt.newTree newLit LibTestMain

importTestLibMain()
testAll()

