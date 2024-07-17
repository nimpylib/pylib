srcDir        = "src"
when fileExists("./src/pylib/version.nim"):  # when installing
  assert srcDir == "src"
  import "./src/pylib/version" as libver
  # `import as` to avoid compile error against `version = Version`
else:  # after installed
  import "pylib/version" as libver

version       = Version
author        = "Danil Yarantsev (Yardanico), Juan Carlos (juancarlospaco), lit (litlighilit)"
description   = "Nim library with python-like functions and operators"
license       = "MIT"
skipDirs      = @["examples"]

requires "nim >= 1.6.0"  # ensure `pydef.nim`c's runnableExamples works

task testJs, "Test JS":
  selfExec "js -r -d:nodejs tests/tester"

task testC, "Test C":
  selfExec "r --mm:orc tests/tester"

import std/os
let
  libDir = srcDir / "pylib/Lib"

func getArgs(taskName: string): seq[string] =
  ## cmdargs: 1 2 3 4 5 -> 1 4 3 2 5
  var rargs: seq[string]
  let argn = paramCount()
  for i in countdown(argn, 0):
    let arg = paramStr i
    if arg == taskName:
      break
    rargs.add arg
  if rargs.len > 1:
    swap rargs[^1], rargs[0] # the file must be the last, others' order don't matter
  return rargs

func getSArg(taskName: string): string = quoteShellCommand getArgs taskName

func handledArgs(args: var seq[string], def_arg: string) =
  ## makes args: @[option..., arg/"ALL"]
  if args.len == 0:
    args.add def_arg
    return
  let lastArg = args[^1]
  if lastArg[0] == '-': args.add def_arg
  elif lastArg == "ALL": args[^1] = def_arg
  # else, the last shall be a nim file

func getHandledArg(taskName: string, def_arg: string): string =
  ## the last param can be an arg, if given,
  ##
  ## def_arg is set as the last element when the last is not arg or is "ALL",
  ## if no arg, then sets def_arg as the only.
  var args = getArgs taskName
  args.handledArgs def_arg
  result = quoteShellCommand args

task testDoc, "cmdargs: if the last is arg: " & 
    "ALL: gen for all(default); else: a nim file":
  let def_arg = srcDir / "pylib.nim"
  let sargs = getHandledArg("testDoc", def_arg)
  selfExec "doc --project --outdir:docs " & sargs


const nimSuf = ".nim"

proc testLib(fp: string, sargs: string) =
  var cmd = "doc"
  if fp.endsWith nimSuf:
    if (fp[0..(fp.len - nimSuf.len-1)] & "_impl").dirExists:
      cmd.add " --project"
    selfExec cmd & " --outdir:docs/Lib " & sargs & ' ' & fp

task testLibDoc, "Test doc-gen and runnableExamples, can pass several args":
  var args = getArgs "testLibDoc"
  let def = "ALL"
  args.handledArgs def
  let fpOrDef = args.pop()
  let sargs = quoteShellCommand args
  if fpOrDef == def:
    for t in walkDir libDir:
      if t.kind in {pcDir, pcLinkToDir}: continue
      let fp = t.path
      testLib fp, sargs
  else:
    testLib fpOrDef, sargs

task testDocAll, "Test doc and Lib's doc":
  testDocTask()
  testLibDocTask()

task testBackends, "Test C, Js, ..":
  # Test C
  testCTask()
  # Test JS
  testJsTask()

task test, "Runs the test suite":
  testBackendsTask()
  # Test all runnableExamples
  testDocAllTask()
