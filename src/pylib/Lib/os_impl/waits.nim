
import ../resource_impl/types
from ./common import raiseErrno
import ./util/handle_signal

const DWin = defined(windows)
when DWin:
  import ../../private/iph_utils  # with_Py_SUPPRESS_IPH
else:
  from std/posix import Pid

when DWin:
  type Res = int
  type WAIT_TYPE = cint
  proc cwait(termstat: var cint, pid: cint, options: cint): Res{.importc: "_cwait", header: "<process.h>".}
  proc c_waitpid(pid: cint, status: var WAIT_TYPE, options: cint): Res =
    with_Py_SUPPRESS_IPH:
      result = cwait(status, pid, options)
  template handle_status(res: Res): int = status shl 8
  template decl_WAIT_STATUS(status; val: cint = 0) =
    var status: WAIT_TYPE = val

elif defined(unix):
  type Res = cint
  type WAIT_TYPE{.importc.} = cint # also may be union
  proc c_waitpid(pid: cint, status: var WAIT_TYPE, options: cint): Res{.importc: "waitpid", header: "<sys/wait.h>".}
  template handle_status(res: Res): int = status.int

  template decl_STATUS_INIT(status; val: cint = 0) =
    var status{.noInit.}: WAIT_TYPE
    {.emit: ["WAIT_STATUS_INIT(", status, ") = ", val, ");"].}
  
  proc WAIT_STATUS_INT(status: WAIT_TYPE): cint{.inline.} =
    {.emit: [result, "= WAIT_STATUS_INT(", status, ")"].}

when not DWin:
  template genW(name){.dirty.} =
    proc name(status: WAIT_TYPE): cint{.importc, header: "<sys/wait.h>".}
    proc name*(status: int): bool =
      decl_STATUS_INIT(wait_status, status.cint)
      name(wait_status) != 0

  genW WCOREDUMP
  genW WIFCONTINUED
  genW WIFSTOPPED
  genW WIFSIGNALED
  genW WIFEXITED
  genW WEXITSTATUS
  genW WTERMSIG
  genW WSTOPSIG

  template genWConst(name){.dirty.} =
    let `c name`{.importc: astToStr(name), header: "<sys/wait.h>".}: cint
    let name* = int `c name`

  genWConst WCONTINUED
  genWConst WEXITED
  genWConst WSTOPPED
  genWConst WUNTRACED
  genWConst WNOHANG
  genWConst WNOWAIT


template waitX_impl[R](res, status: untyped; resExpr){.dirty.} =
  decl_STATUS_INIT(status)
  initVal_with_handle_signal(res, resExpr)

when declared(c_waitpid):
  proc waitpid*(pid: int, options: int): tuple[pid: int, status: int] =
    let
      options = options.cint
      pid = pid.cint
    var res: Res
    waitX_impl[Res](res, status, c_waitpid(pid, status, options))
    (res.int, handle_status(status))

when not DWin:
  proc wait(status: var WAIT_TYPE): Res{.importc, header: "<sys/wait.h>".}
  proc wait*(): tuple[pid: int, status: int] =
    var res: Pid
    waitX_impl[Pid](res, status, wait(status))
    (res.int, WAIT_STATUS_INT status)

  proc wait_helper(pid: Pid, status: cint, rusage: var posix.RUsage):
      tuple[pid: int, status: int, rusage: struct_rusage] =
    if pid == -1:
      raiseErrno()
    
    #[If wait succeeded but no child was ready to report status, ru will not
    have been populated.]#
    if pid == 0:
      zeroMem(addr rusage, sizeof(rusage))
    let res = rusage.toPyObject()
    (pid.int, status.int, res)

  proc wait3(status: var WAIT_TYPE, options: cint, rusage: var posix.RUsage): Res{.importc, header: "<sys/wait.h>".}
  proc wait3*(options: int): tuple[pid: int, status: int, rusage: struct_rusage] =
    var
      res: Pid
      ru: posix.RUsage
    waitX_impl[Pid](res, status, wait3(status, options.cint, ru))
    wait_helper(res, WAIT_STATUS_INT(status), ru)

  proc wait4(pid: Pid, status: var WAIT_TYPE, options: cint, rusage: var posix.RUsage): Res{.importc, header: "<sys/wait.h>".}
  proc wait4*(pid: int, options: int): tuple[pid: int, status: int, rusage: struct_rusage] =
    var
      res: Pid
      ru: posix.RUsage
    let pid = pid.Pid
    waitX_impl[Pid](res, status, wait4(pid, status, options.cint, ru))
    wait_helper(res, WAIT_STATUS_INT(status), ru)

proc waitstatus_to_exitcode*(status: int): int =
  when not defined(windows):
    decl_STATUS_INIT(wait_status, status.cint)
    var exitcode: cint
    if bool WIFEXITED(wait_status):
      exitcode = WEXITSTATUS(wait_status)
      # Sanity check to provide warranty on the function behavior.
      # It should not occur in practice
      if exitcode < 0:
        raise newException(ValueError, "invalid WEXITSTATUS: " & $exitcode)
    elif bool WIFSIGNALED(wait_status):
      let signum = WTERMSIG(wait_status)
      # Sanity check to provide warranty on the function behavior.
      # It should not occur in practice
      if signum <= 0:
        raise newException(ValueError, "invalid WTERMSIG: " & $signum)
      exitcode = -signum
    elif bool WIFSTOPPED(wait_status):
      # Status only received if the process is being traced
      # or if waitpid() was called with WUNTRACED option.
      let signum = WSTOPSIG(wait_status)
      raise newException(ValueError, "process stopped by delivery of signal " & $signum)
    else:
      raise newException(ValueError, "invalid wait status: " & $status)
    result = int exitcode
  else:
    # Windows implementation: see os.waitpid() implementation
    # which uses _cwait().
    let exitcode = (status.uint64 shr 8)
    # ExitProcess() accepts an UINT type:
    # reject exit code which doesn't fit in an UINT
    if exitcode > cuint.high.uint64:
      raise newException(ValueError, "invalid exit code: " & $exitcode)
    result = exitcode.int

