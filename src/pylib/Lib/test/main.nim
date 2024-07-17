
import std/strutils
import std/os
const SourceDir = currentSourcePath().parentDir
when defined(js):
  const jsExcludes = ("skipJs.txt").slurp.strip().splitLines()

import std/macros

var allTests{.compileTime.}: seq[string]
static:
  # walkFiles is {.error.} when nims
  for t in walkDir(SourceDir):
    if t.kind == pcDir or t.kind == pcLinkToDir: continue
    let name = t.path.lastPathPart
    if name[0] != 't' or name.startsWith "temp": continue
    when defined(js):
      var nname = name
      nname.removeSuffix(".nim")
      nname.removePrefix("t")
      nname.removePrefix("_")
      if nname in jsExcludes: continue
      nname.removePrefix("est_")
      if nname in jsExcludes: continue
    allTests.add t.path

macro testAll* =
  ## .. warning:: this causes `{.warning[UnusedImport]: off.}`
  ## .. hint:: this generates `import` stmt, thus must be on top level
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
