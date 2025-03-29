
import ./util

const SIZEOF_RLIMIT_T* = from_c_int(SIZEOF_RLIMIT_T, 8):
  {.emit: """/*INCLUDESECTION*/
#include <sys/resource.h>
#define SIZEOF_RLIMIT_T sizeof(rlim_t)
""".}

AC_LINK_IFELSE HAVE_PRLIMIT, false:
  import std/posix
  proc prlimit(pid: Pid, resource: cint, new_limit, old_limit: ptr RLimit): cint {.
    importc, header: "<sys/resource.h>".}
  discard prlimit(0, 0, nil, nil)

AC_LINK_IFELSE HAVE_GETPAGESIZE, false:
  proc getpagesize(): cint {.importc, header: "<unistd.h>".}
  discard getpagesize()

AC_LINK_IFELSE HAVE_SYSCONF_PAGE_SIZE, false:
  let SC_PAGE_SIZE{.importc, header: "<unistd.h>".}: cint
  proc sysconf(name: cint): cint {.importc, header: "<unistd.h>".}
  discard sysconf(SC_PAGE_SIZE)
