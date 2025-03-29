
import ./types
import std/posix except EINVAL, EPERM
import ../n_errno
import ../../pyerrors/oserr
from ./csyms import HAVE_PRLIMIT, HAVE_GETPAGESIZE, HAVE_SYSCONF_PAGE_SIZE

proc getrusage*(who: int): struct_rusage =
  var ru: posix.RUsage
  if getrusage(who.cint, addr ru) == -1:
    if isErr(EINVAL):
      raise newException(ValueError, "Invalid who value")
    raiseErrno()
  ru.toPyObject()

type
  py_rlimit* = tuple
    rlim_cur: int
    rlim_max: int

# XXX: NIM-BUG: rlim_cur and rlim_max are int over unsigned in std/posix

proc py2rlimit(limits: py_rlimit, rl_out: var RLimit) =
  rl_out.rlim_cur = limits.rlim_cur
  rl_out.rlim_max = limits.rlim_max

proc rlimit2py(rl_in: RLimit): py_rlimit = (rl_in.rlim_cur, rl_in.rlim_max)

let RLIM_NLIMITS{.importc, header: "<sys/resource.h>".}: cint

proc checked_resource*(resource: int): cint =
  if resource < 0 or resource >= RLIM_NLIMITS:
    raise newException(ValueError, "Invalid resource specified")
  cast[cint](resource)

proc getrlimit*(resource: int): py_rlimit =
  var rl: RLimit
  if getrlimit(checked_resource(resource), rl) == -1:
    raiseErrno()
  rlimit2py(rl)

proc raise_inval =
  raise newException(ValueError, "current limit exceeds maximum limit")
proc setrlimit*(resource: int, limits: py_rlimit) =
  var rl: RLimit
  py2rlimit(limits, rl)
  if setrlimit(checked_resource(resource), rl) == -1:
    if isErr(EINVAL): raise_inval()
    elif isErr(EPERM):
      raise newException(ValueError, "not allowed to raise maximum limit")
    raiseErrno()

when HAVE_PRLIMIT:
  proc prlimit(pid: Pid, resource: cint, new_limit: ptr RLimit, old_limit: var RLimit): cint {.
    importc, header: "<sys/resource.h>".}

  proc prlimit*(pid: int, resource: int): py_rlimit{.discardable.} =
    let
      pid = Pid pid
      resource = checked_resource(resource)
    var old_limit: RLimit
    if prlimit(pid, resource, nil, old_limit) == -1:
      if isErr(EINVAL): raise_inval()
      raiseErrno()
    rlimit2py(old_limit)

  proc prlimit*(pid: int, resource: int, limits: py_rlimit): py_rlimit{.discardable.} =
    let
      pid = Pid pid
      resource = checked_resource(resource)
    var old_limit, new_limit: RLimit
    
    py2rlimit(limits, new_limit)
    if prlimit(pid, resource, addr new_limit, old_limit) == -1:
      if isErr(EINVAL): raise_inval()
      raiseErrno()
    
    rlimit2py(old_limit)

when HAVE_GETPAGESIZE:
  proc c_getpagesize(): cint{.importc, header: "<unistd.h>".}
  proc getpagesize*(): int = int c_getpagesize()
elif HAVE_SYSCONF_PAGE_SIZE:
  let SC_PAGE_SIZE{.importc, header: "<unistd.h>".}: cint
  proc c_sysconf(name: cint): cint{.importc, header: "<unistd.h>".}
  proc getpagesize*(): int = int c_sysconf(SC_PAGE_SIZE)

