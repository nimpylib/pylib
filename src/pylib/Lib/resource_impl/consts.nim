
from ./csyms import SIZEOF_RLIMIT_T, RUSAGE_BOTH, RUSAGE_THREAD

const RLIM_INFINITY* =
  when SIZEOF_RLIMIT_T == 8:
    0xffffffffffffffffu
  else:
    0xffffffffu

template wrap(name){.dirty.} =
  let `c name`{.importc: astToStr(name), header: "<sys/resource.h>".}: cint
  let name* = int `c name`
template wrap(name, os){.dirty.} =
  when defined(os):
    wrap(name)
template wrapIfE(name){.dirty.} =
  when declared(name) and name != low(int):
    const name* = int name

wrap(RLIMIT_CORE)
wrap(RLIMIT_CPU)
wrap(RLIMIT_FSIZE)
wrap(RLIMIT_DATA)
wrap(RLIMIT_STACK)
wrap(RLIMIT_RSS)
wrap(RLIMIT_NPROC)
wrap(RLIMIT_NOFILE)
wrap(RLIMIT_OFILE)
wrap(RLIMIT_MEMLOCK)
wrap(RLIMIT_VMEM, freebsd)
wrap(RLIMIT_AS)
when defined(linux):
  wrap(RLIMIT_MSGQUEUE)
  wrap(RLIMIT_NICE)
  wrap(RLIMIT_RTPRIO)
  wrap(RLIMIT_RTTIME)
  wrap(RLIMIT_SIGPENDING)
when defined(freebsd):
  wrap(RLIMIT_SBSIZE)
  wrap(RLIMIT_SWAP)
  wrap(RLIMIT_NPTS)
  wrap(RLIMIT_KQUEUES)

wrap(RUSAGE_SELF)
wrap(RUSAGE_CHILDREN)
wrapIfE(RUSAGE_BOTH)
wrapIfE(RUSAGE_THREAD)
