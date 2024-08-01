
import ../private/iph_utils
import ./errnoHandle

when MS_WINDOWS:
  proc lseek(fd: cint, offset: int64, origin: cint): int64 {.
    importc: "_lseeki64", header: "<io.h>".}
  {.push header: "<stdio.h>".}
else:
  import std/posix
  {.push header: "<unistd.h>".}
let
  SEEK_SET{.importc.}: cint
  SEEK_CUR{.importc.}: cint
  SEEK_END{.importc.}: cint
{.pop.}

let ordSEEK =
  SEEK_SET == 0 and
  SEEK_SET == 1 and
  SEEK_END == 2

proc lseek*(fd: int, position: int64, whence: int): int64 =
  let how = if ordSEEK: whence.cint
  else:
    case whence
    of 0: SEEK_SET
    of 1: SEEK_CUR
    of 2: SEEK_END
    else:
      # err is handled below;
      # also, SEEK_HOLE, SEEL_DATA may be accepted too
      whence.cint

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


