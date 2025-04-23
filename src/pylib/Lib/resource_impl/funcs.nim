
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
  py_rlimit_abc = concept self
    self.len is int
    self[int] is int

# XXX: NIM-BUG: rlim_cur and rlim_max are int over unsigned in std/posix

proc py2rlimit(limits: py_rlimit, rl_out: var RLimit) =
  rl_out.rlim_cur = limits.rlim_cur
  rl_out.rlim_max = limits.rlim_max

template py2rlimit[T](limits: T{atom}, rl_out: var RLimit) =
  assert limits.len == 2
  rl_out.rlim_cur = limits[0]
  rl_out.rlim_max = limits[1]
template py2rlimit[T](limits: T, rl_out: var RLimit) =
  let li = limits
  py2rlimit(li, rl_out)

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

proc setrlimitWrap(resource: int, rl: var RLimit) =
  if setrlimit(checked_resource(resource), rl) == -1:
    if isErr(EINVAL): raise_inval()
    elif isErr(EPERM):
      raise newException(ValueError, "not allowed to raise maximum limit")
    raiseErrno()

template setrlimit*[T: py_rlimit_abc|py_rlimit](resource: int, limits: T) =
  ## this is defined as `template`.
  ## Because if being `proc`, py_rlimit_abc match cannot work
  bind py2rlimit, setrlimitWrap
  mixin len, `[]`
  var rl: RLimit
  py2rlimit(limits, rl)
  setrlimitWrap(resource, rl)

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

  proc prlimitWrap(pid: Pid, resource: cint, new_limit: var RLimit): py_rlimit{.discardable.} =
    var old_limit: RLimit
    if prlimit(pid, resource, addr new_limit, old_limit) == -1:
      if isErr(EINVAL): raise_inval()
      raiseErrno()
    rlimit2py(old_limit)

  template prlimit*[T: py_rlimit_abc|py_rlimit](pid: int, resource: int, limits: T): py_rlimit =
    ## discardable.
    ## 
    ## this is defined as `template`.
    ## Because if being `proc`, py_rlimit_abc match cannot work
    bind Pid, checked_resource, RLimit, py2rlimit, prlimitWrap
    mixin len, `[]`
    let
      tpid = Pid pid
      tresource = checked_resource(resource)
    var new_limit: RLimit
    py2rlimit(limits, new_limit)
    prlimitWrap(tpid, tresource, new_limit)

when HAVE_GETPAGESIZE:
  proc c_getpagesize(): cint{.importc: "getpagesize", header: "<unistd.h>".}
  proc getpagesize*(): int = int c_getpagesize()
elif HAVE_SYSCONF_PAGE_SIZE:
  let SC_PAGE_SIZE{.importc, header: "<unistd.h>".}: cint
  proc c_sysconf(name: cint): cint{.importc, header: "<unistd.h>".}
  proc getpagesize*(): int = int c_sysconf(SC_PAGE_SIZE)

