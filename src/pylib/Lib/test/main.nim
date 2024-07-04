
import std/strutils
const jsExcludes = "skipJs.txt".slurp.strip().splitLines()

import std/macros
import std/os

const SourceDir = currentSourcePath().parentDir

var allTests{.compileTime.}: seq[string]
static:
  # walkFiles is {.error.} when nims
  for t in walkDir(SourceDir):
    if t.kind == pcDir or t.kind == pcLinkToDir: continue
    let name = t.path.lastPathPart
    if name[0] != 't' or name.startsWith "temp": continue
    when defined(js):
      if name in jsExcludes: continue
    allTests.add t.path

macro testAll* =
  ## .. warning:: this causes `{.warning[UnusedImport]: off.}`
  result = newNimNode nnkImportStmt
  for i in allTests:
    let strNode = newLit i
    #[  # the following doesn't compile
    result.add quote do:
      `strNode`{.used.}
    ]#
    result.add strNode
  result = quote do:
    {.warning[UnusedImport]: off.}
    `result`

when isMainModule:
  testAll()
