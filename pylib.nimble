version       = "0.5.0"
author        = "Danil Yarantsev (Yardanico), Juan Carlos (juancarlospaco), lit (litlighilit)"
description   = "Nim library with python-like functions and operators"
license       = "MIT"
skipDirs      = @["examples"]
srcDir        = "src"

requires "nim >= 1.6.0"  # ensure `pydef.nim`c's runnableExamples works

task testJs, "Test JS":
  exec "nim js -r -d:nodejs --experimental:strictFuncs tests/tester"

task testC, "Test C":
  exec "nim r --experimental:strictFuncs --mm:orc tests/tester"

task testDoc, "Test doc-gen and runnableExamples":
  exec "nim doc --project --outdir:docs src/pylib.nim"

task test, "Runs the test suite":
  # Test C
  testCTask()
  # Test JS
  testJsTask()
  # Test all runnableExamples
  testDocTask()
