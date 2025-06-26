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

requires "nim > 2.0.4"
# 1.6.0: ensure `pydef.nim`c's runnableExamples works
# 2.0.4: `Lib/sys_impl/getencodings` `template importPython(submod, sym) = from ../../Python/submod import sym` doesn't work

import std/os

proc runTestament(targets = "c") =
  for path in listDirs("./tests/testaments"):
    if path.lastPathPart in ["nimcache", "testresults"]:
      continue
    exec "testament --targets:" & targets.quoteShell &  " pat " & quoteShell path

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

template mytask(name: untyped, taskDesc: string, body){.dirty.} =
  task name, taskDesc:
    let taskName = astToStr(name)
    body

template taskWithArgs(name, taskDesc, body){.dirty.} =
  mytask name, taskDesc:
    var args = getArgs taskName
    body

task testJs, "Test JS":
  selfExec "js -r -d:nodejs tests/tester"
  runTestament "js"

task testC, "Test C":
  selfExec "r --mm:orc tests/tester"
  runTestament "c"

taskWithArgs testament, "Testament":
  var targets = args.quoteShellCommand
  if targets.len == 0: targets = "c js"
  runTestament targets

let
  libDir = srcDir / "pylib/Lib"

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

mytask testDoc, "cmdargs: if the last is arg: " & 
    "ALL: gen for all(default); else: a nim file":
  let def_arg = srcDir / "pylib.nim"
  let sargs = getHandledArg(taskName, def_arg)
  selfExec "doc --project --outdir:docs " & sargs


const nimSuf = ".nim"

proc testLib(fp: string, sargs: string) =
  var cmd = "doc"
  if fp.endsWith nimSuf:
    if (fp[0..(fp.len - nimSuf.len-1)] & "_impl").dirExists:
      cmd.add " --project"
    selfExec cmd & " --outdir:docs/Lib " & sargs & ' ' & fp

taskWithArgs testLibDoc, "Test doc-gen and runnableExamples, can pass several args":
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

task rei, "reinstall, for dev only!":
  #[ if uninstalling in cwd, may failed with: 
Could not read package info file in ~/.nimble/pkgs2/pylib-xxx/pylib.nimble;
  Reading as ini file failed with: 
    Invalid section: .
  Evaluating as NimScript file failed with: 
    ~/.nimble/pkgs2/pylib-xxx/pylib.nimble(4, 32) Error: cannot open file: ./src/pylib/version
printPkgInfo() failed.
]#
  withDir "..":
    exec "nimble uninstall -y pylib"
  
  exec "nimble install"

func stripLfOrCrlf(s: var string) =
  ## Copied from strutils.stripLineEnd
  if s.len > 0:
    case s[^1]
    of '\n':
      if s.len > 1 and s[^2] == '\r':
        s.setLen s.len-2
      else:
        s.setLen s.len-1
    # of '\r', '\v', '\f': s.setLen s.len-1
    else:
      discard

taskWithArgs changelog, "output for changelog files":
  if args.len == 0:
    args.add "HEAD"
  template catRng(a, b): string = a & ".." & b
  let sufArg =
    if args.len == 1:
      let arg = args[0]
      if ".." in arg: arg
      else:
        let lastTagExecRes = gorgeEx("git describe --tags --abbrev=0")
        assert lastTagExecRes.exitCode == 0
        var lastTag = lastTagExecRes.output
        # XXX: On Windows it ends with \r\n. But nothing on Linux
        lastTag.stripLfOrCrlf
        catRng(lastTag, arg)
    else:
      let
        rng2 = args.pop()
        rng1 = args.pop()
      args.add catRng(rng1, rng2)
      quoteShellCommand(args)
  
  exec """git log --reverse --format="%s. (%h)" """ & sufArg

