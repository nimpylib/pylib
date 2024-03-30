
import std/os

import ./common

{.push header: "<errno.h>".}
let errno{.importc.}: cint
let EINTR{.importc.}: cint
{.pop.}

when defined(windows):
  import std/winlean
  when defined(nimPreviewSlimSystem):
    import std/widestrs

  proc c_wopen(path: WideCString, flags: cint): cint{.
    varargs,importc:"_wopen", header:"<io.h>".}

  # if `fd` is invalide, functions returns -1 and errno is set to EBADF.
  proc c_close(fd: cint): cint{.importc:"_close", header:"<io.h>".}
else:
  import std/posix

  proc c_openat(
    dirfd: cint, pathname: cstring, flags: cint
  ): cint{.varargs, importc: "openat", header: "<fcntl.h>".}
  
  template c_close(fd): cint = posix.close(fd)

  {.emit:"""
/*VARSECTION*/
#ifdef AT_FDCWD
#define DEFAULT_DIR_FD (int)AT_FDCWD
#else
#define DEFAULT_DIR_FD (-100)
#endif
""" .}
  let DEFAULT_DIR_FD{.importc.}: cint


proc open*(path: PathLike, flags: int, mode=0o777, dir_fd = -1): int =

  var fd: cint
  let spath = $path
  while true:
    when defined(windows):
      let cflags = flags.cint or O_NOINHERIT 
      fd = c_wopen(newWideCString(spath), cflags, mode)
    else:
      let cflags = flags.cint or O_CLOEXEC
      if dir_fd != DEFAULT_DIR_FD:
        fd = c_openat(dir_fd, spath.cstring, cflags, mode)
      else:
        fd = posix.open(spath.cstring, cflags, mode)
      discard setInheritable(FileHandle fd, false)
    if not (
      fd < 0 and errno == EINTR
    ): break
  if fd < 0:
    raiseOSError(osLastError(), "can't open " & spath)
  result = fd


proc close*(fd: int) =
  if c_close(fd.cint) == -1.cint:
    raiseOSError(osLastError(), "close")
