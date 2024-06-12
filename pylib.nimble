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
  exec "nim js -r -d:nodejs --experimental:strictFuncs tests/tester"

task testC, "Test C":
  exec "nim r --experimental:strictFuncs --mm:orc tests/tester"

import std/os
task testDoc, "Test doc-gen and runnableExamples":
  var arg = "pylib.nim"
  let argn = paramCount()
  if argn > 1:
    let a1 = paramStr argn-1
    if a1 == "e" or a1 == "testDoc":
      arg = paramStr argn
  exec "nim doc --project --outdir:docs " & srcDir / arg

task testLibDoc, "Test doc-gen and runnableExamples":
  let libDir = srcDir / "pylib/Lib"
  #for f in walkFiles libDir/"*.nim":  # walkFiles not support nims
  let nimSuf = ".nim"
  for t in walkDir libDir:
    if t.kind in {pcDir, pcLinkToDir}: continue
    let fp = t.path
    var cmd = "nim doc"
    if fp.endsWith nimSuf:
      if (fp[0..(fp.len - nimSuf.len-1)] & "_impl").dirExists:
        cmd.add " --project"
      exec cmd & " --outdir:docs/Lib " & fp
  
task test, "Runs the test suite":
  # Test C
  testCTask()
  # Test JS
  testJsTask()
  # Test all runnableExamples
  testDocTask()
  testLibDocTask()
