## posixmodule, also mimic posix api for Windows

import ../../io_abc

import ./open_close
import std/os

when defined(windows):
  # errno_t _chsize(int _FileHandle, __int64 _Size);
  proc chsize_s(fd: cint, size: int64): cint{.importc:"_chsize_s", header:"<io.h>".}
  proc c_strerror(errnum: cint): cstring {.
    importc: "strerror", header: "<string.h>".}
else:
  import std/posix
  var errno{.importc, header: "<errno.h>".}: cint

template raiseErrno(err: cint) =
  raise newException(OSError, $c_strerror(err))

proc ftruncate*(file: Positive, length: int64) =
  when defined(windows):
    let err = chsize_s(file.cint, length)
    if err.int != 0:
      raiseErrno err
  else:
    let err = posix.ftruncate(file.cint, length.Off)
    if err.int != 0:
      raiseErrno errno

proc truncate*(file: CanIOOpenT, length: Natural) =
  when file is int:
    ftruncate file, length
  else:
    let fd = open(file, os.O_WDONLY)
    ftruncate fd, length
    close(fd)

