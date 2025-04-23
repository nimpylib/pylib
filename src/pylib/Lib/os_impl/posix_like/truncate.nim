
import ../common

when defined(js):
  proc ftruncateSync(file: cint; len: cint){.importNode(fs, ftruncateSync).}
  proc ftruncateImpl(file: Positive; length: Natural) =
    catchJsErrAndRaise ftruncateSync(file.cint, length.cint)
  proc truncateSync(file: cstring; len: cint){.importNode(fs, truncateSync).}
  proc truncateImpl(file: CanIOOpenT; length: Natural) =
    when file is int:
      ftruncateImpl file, length
    else:
      catchJsErrAndRaise truncateSync(file.cstring, length.cint)

else:
  import std/os
  import ./open_close
  when defined(windows):
    # errno_t _chsize_s(int _FileHandle, __int64 _Size);
    proc chsize_s(fd: cint, size: int64): cint{.importc:"_chsize_s", header:"<io.h>".}
  else:
    import std/posix

  template ftruncateImplAux(file: Positive, length: int64): cint =
    when defined(windows):
      chsize_s(file.cint, length)
    else:
      posix.ftruncate(file.cint, length.Off)

  proc ftruncateImpl(file: Positive, length: int64) =
      let err = ftruncateImplAux(file, length)
      if err.int != 0:
        raiseErrno err

  proc truncateImpl(file: CanIOOpenT, length: Natural) =
    when file is int:
      ftruncateImpl file, length
    else:
      let fd = open(file, os.O_WDONLY)
      let err = ftruncateImpl(fd, length)
      if 0 != err:
        file.raiseErrnoWithPath err
      close(fd)

proc ftruncate*(file: Positive, length: Natural) =
  sys.audit("os.truncate", file, length)
  ftruncateImpl(file, length)

proc truncate*(file: CanIOOpenT, length: Natural) =
  sys.audit("os.truncate", file, length)
  truncateImpl(file, length)

