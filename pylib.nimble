version       = "0.4.0"
author        = "Danil Yarantsev (Yardanico), Juan Carlos (juancarlospaco)"
description   = "Nim library with python-like functions and operators"
license       = "MIT"
skipDirs      = @["examples"]
srcDir        = "src"

requires "nim >= 1.2.0"

task test, "Runs the test suite":
  exec "nim r --experimental:strictFuncs --gc:orc tests/tester"
  # Test all runnableExamples
  exec "nim doc --project --outdir:docs src/pylib.nim"
