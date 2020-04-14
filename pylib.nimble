version       = "0.1.0"
author        = "Danil Yarantsev (Yardanico), Juan Carlos (juancarlospaco)"
description   = "Nim library with python-like functions and operators"
license       = "MIT"
skipDirs      = @["examples"]
srcDir        = "src"

requires "nim >= 1.0.0"

task test, "Runs the test suite":
  exec "nim c -r tests/tester"
