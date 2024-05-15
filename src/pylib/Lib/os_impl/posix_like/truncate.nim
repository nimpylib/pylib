
import ../common

import ./open_close
import std/os

when defined(windows):
  # errno_t _chsize_s(int _FileHandle, __int64 _Size);
  proc chsize_s(fd: cint, size: int64): cint{.importc:"_chsize_s", header:"<io.h>".}
else:
  import std/posix

template ftruncateImpl(file: Positive, length: int64): cint =
  when defined(windows):
    chsize_s(file.cint, length)
  else:
    posix.ftruncate(file.cint, length.Off)

proc ftruncate*(file: Positive, length: int64) =
    let err = ftruncateImpl(file, length)
    if err.int != 0:
      raiseErrno()

proc truncate*(file: CanIOOpenT, length: Natural) =
  when file is int:
    ftruncate file, length
  else:
    let fd = open(file, os.O_WDONLY)
    if 0 != int ftruncateImpl(fd, length):
      file.raiseErrnoWithPath()
    close(fd)

