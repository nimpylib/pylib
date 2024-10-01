
import std/os

import ../common
import ../consts

when defined(js):
  when defined(nodejs):
    import std/jsffi
    proc openSync(path: cstring, flags, mode: cint): cint{.importjs: "require('fs').openSync(@)".}
    # in fact flags, mode is optional and accepts cstring, but we don't need such variants here
    proc closeSync(fd: cint){.importjs: "require('fs').closeSync(@)".}
    proc c_close(fd: cint): int =
      catchJsErrAsCode "require('fs').closeSync(`fd`)"

    proc c_close(fd: cint, msg: var string): int =
      ## compat close
      catchJsErrAsCode msg, "require('fs').closeSync(`fd`)"
  else:
    proc openSync(path: cstring, flags, mode: cint): cint{.error:
      "not impl for non-nodejs JS engine".}
    # XXX: Deno.openSync returns FsFile instead of integer

else:
  let EINTR{.importc, header: "<errno.h>".}: cint

  when defined(windows):
    when defined(nimPreviewSlimSystem):
      import std/widestrs

    proc c_wopen(path: WideCString, flags: cint): cint{.
      varargs, importc:"_wopen", header:"<io.h>".}

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
    let DEFAULT_DIR_FD{.importc, nodecl.}: cint


proc open*(path: PathLike, flags: int, mode=0o777, dir_fd = -1): int =
  ## `dir_fd` is ignored under Windows
  when defined(js):
    var msg: string
    let
      p = cstring($path)
      f = flags.cint
      m = mode.cint
    var result_cint: cint
    let err = catchJsErrAsCode msg:
      "`result_cint` = openSync(`p`, `f`, `m`)"
    if err != 0:
      raiseErrno err, msg
    result = int result_cint
  else:
    var fd: cint
    let spath = $path
    while true:
      when defined(windows):
        let cflags = flags.cint or O_NOINHERIT 
        fd = c_wopen(newWideCString(spath), cflags, mode)
      else:
        let cflags = flags.cint or O_CLOEXEC
        if dir_fd != -1 and dir_fd != DEFAULT_DIR_FD:
          fd = c_openat(dir_fd.cint, spath.cstring, cflags, mode)
        else:
          fd = posix.open(spath.cstring, cflags, Mode mode)
        discard setInheritable(FileHandle fd, false)
      if not (
        fd < 0 and errno == EINTR
      ): break
    if fd < 0:
      path.raiseErrnoWithPath()
    result = fd


proc close*(fd: int) =
  when defined(js):
    var msg = ""
    let res = c_close(fd.cint, msg)
    if res != 0:
      raise newException(OSError, msg & ", close fd: " & $fd)
  else:
    if c_close(fd.cint) == -1.cint:
      raiseErrno("close fd: " & $fd)

proc closerange*(fd_low, fd_high: int) =
  for fd in fd_low..<fd_high:
    discard c_close(fd.cint)
