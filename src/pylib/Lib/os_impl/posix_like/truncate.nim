
import ../../../io_abc

import ./open_close
import ./errnoHandle
import std/os

when defined(windows):
  # errno_t _chsize(int _FileHandle, __int64 _Size);
  proc chsize_s(fd: cint, size: int64): cint{.importc:"_chsize_s", header:"<io.h>".}
else:
  import std/posix

template raiseErrno(err: cint) =
  raise newException(OSError, errnoMsg(err))

proc ftruncate*(file: Positive, length: int64) =
  when defined(windows):
    let err = chsize_s(file.cint, length)
    if err.int != 0:
      raiseErrno err
  else:
    let err = posix.ftruncate(file.cint, length.Off)
    if err.int != 0:
      raiseErrno posix.errno

proc truncate*(file: CanIOOpenT, length: Natural) =
  when file is int:
    ftruncate file, length
  else:
    let fd = open(file, os.O_WDONLY)
    ftruncate fd, length
    close(fd)

