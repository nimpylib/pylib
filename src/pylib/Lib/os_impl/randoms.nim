
import std/sysrand

when NimMajor < 2:
  import std/os
else:
  import std/oserrors

import ../../nimpatch/newUninit
import ../../pyconfig/bootstrap_hash
import ./private/defined_macros
#[
## | Targets              | Implementation        | set errno
## | :---                 | ----:                 | :---
## | Windows              | `BCryptGenRandom`_    | (none)
## | Linux                | `getrandom`_          | EAGAIN,EFAULT,EINTR,EINVAL,ENOSYS
## | MacOSX               | `SecRandomCopyBytes`_ | (none)
## | iOS                  | `SecRandomCopyBytes`_ | (none)
## | OpenBSD              | `getentropy openbsd`_ | EINVAL,EIO
## | FreeBSD              | `getrandom freebsd`_  | EFAULT,EINVAL
## | JS (Web Browser)     | `getRandomValues`_    | (not care)
## | Node.js              | `randomFillSync`_     | (not care)
## | Other Unix platforms | `/dev/urandom`_       | ENOENT,ENXIO,ENODEV,EACCES
##
## .. _BCryptGenRandom: https://docs.microsoft.com/en-us/windows/win32/api/bcrypt/nf-bcrypt-bcryptgenrandom
## .. _getrandom: https://man7.org/linux/man-pages/man2/getrandom.2.html
## .. _getentropy: https://www.unix.com/man-page/mojave/2/getentropy
## .. _SecRandomCopyBytes: https://developer.apple.com/documentation/security/1399291-secrandomcopybytes?language=objc
## .. _getentropy openbsd: https://man.openbsd.org/getentropy.2
## .. _getrandom freebsd: https://www.freebsd.org/cgi/man.cgi?query=getrandom&manpath=FreeBSD+12.0-stable
## .. _getRandomValues: https://www.w3.org/TR/WebCryptoAPI/#Crypto-method-getRandomValues
## .. _randomFillSync: https://nodejs.org/api/crypto.html#crypto_crypto_randomfillsync_buffer_offset_size
## .. _/dev/urandom: https://en.wikipedia.org/wiki//dev/random
]#

const mayUseDevUrandom = not defined(js) and not MS_WINDOWS
when mayUseDevUrandom:
  import ../errno_impl/errnoUtils
  {.define: ImportErrnoUtils.}
  import ../../pyerrors/rterr
  template raise_NotImplementedError(msg) =
    raise newException(NotImplementedError, msg)
  {.push importc, header: "<errno.h>".}
  let ENOENT,ENXIO,ENODEV,EACCES: cint
  {.pop.}
  

proc urandom*(size: int): seq[uint8] =
  if size < 0:
    raise newException(ValueError, "negative argument not allowed")
  let size = cast[Natural](size)
  result.setLenUninit size
  if sysrand.urandom(result):
    return

  ## raises as CPython does
  when mayUseDevUrandom:
    if isErr(ENOENT) or isErr(ENXIO) or isErr(ENODEV) or isErr(EACCES):
      raise_NotImplementedError("/dev/urandom (or equivalent) not found")
  ## Win: win32_urandom -> PyErr_SetFromWindowsErr(0);
  ## else: PyErr_SetFromErrno(PyExc_OSError);
  raise newOSError osLastError()

when have_getrandom_syscall:
  import ../errno_impl/errnoConsts
  when not defined(ImportErrnoUtils):
    import ../errno_impl/errnoUtils
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
