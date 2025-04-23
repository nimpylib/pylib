
import ./common
when not defined(js):
  proc c_system(cmd: cstring): cint{.importc: "system", header: "<stdlib.h>".}

proc system*(cmd: string): int{.discardable.} =
  ## os.system
  runnableExamples:
    const
      # can use `os.devnull`
      mydevnull = when defined(windows): "nul" else: "/dev/null"
      e2null = "echo 1 >" & mydevnull
    assert system(e2null) == 0

  sys.audit("os.system", cmd)
  when defined(js):
    let jsStr = cmd.cstring
    var res: c_int
    asm """
    const {exec} = require('node:child_process');
    let childProcess = exec(`jsStr`);
    `res` = childProcess.exitCode;
    """
    result = res.int
  else:
    c_system cmd.cstring

