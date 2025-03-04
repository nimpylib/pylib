
import ../private/iph_utils
import ./errnoHandle
const weirdTarget = defined(js) or defined(nimscript)
when not weirdTarget:
  import ./seek_consts

when MS_WINDOWS:
  proc lseek(fd: cint, offset: int64, origin: cint): int64 {.
    importc: "_lseeki64", header: "<io.h>".}
elif not weirdTarget:
  import std/posix

proc lseek*(fd: int, position: int64, whence: int): int64{.noWeirdTarget.} =
  let how = whence.toCSEEK
  with_Py_SUPPRESS_IPH:
    when MS_WINDOWS:
      result = lseek(
        fd.cint,
        position,
        how
      ).int64
    else:
      result = lseek(
        fd.cint,
        position.Off,
        how
      )
  if result < 0:
    raiseErrno()


