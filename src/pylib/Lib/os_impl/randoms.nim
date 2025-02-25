
import std/sysrand

when NimMajor < 2:
  import std/os
else:
  import std/oserrors

import ../../nimpatch/newUninit
import ../../pyconfig/bootstrap_hash

proc urandom*(size: int): seq[uint8] =
  if size < 0:
    raise newException(ValueError, "negative argument not allowed")
  let size = cast[Natural](size)
  result.setLenUninit size
  if sysrand.urandom(result):
    return

  ## raises as CPython does
  ## Win: win32_urandom -> PyErr_SetFromWindowsErr(0);
  ## else: PyErr_SetFromErrno(PyExc_OSError);
  raise newOSError osLastError()

when have_getrandom_syscall:
  import ../errno_impl/[errnoConsts, errnoUtils]
  import ../signal_impl/c_api
  import ../../pyerrors/oserr

  let SYS_getrandom {.importc, header: "<sys/syscall.h>".}: clong
  const syscallHeader = """#include <unistd.h>
  #include <sys/syscall.h>"""
  proc syscall(n: clong): clong {.
      importc: "syscall", varargs, header: syscallHeader.}


  proc getrandom*(size: int, flags = 0): seq[uint8] =

    if size < 0:
      #$setErrno EINVAL
      raiseErrno EINVAL
    
    var n: int
    result = newSeqUninit[uint8](size)

    while true:
      n = syscall(SYS_getrandom,
        result[0].addr,
        result.len,
        flags
      )
      if n < 0 and isErr EINTR:
        if PyErr_CheckSignals() < 0:
          raiseErrno()

        # getrandom() was interrupted by a signal: retry
        continue

      break

    if n < 0:
      raiseErrno()
    
    if n != size:
      result.setLen n
