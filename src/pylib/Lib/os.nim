
# reference source: Modules/posixmodule.c

import std/os
export os
import std/macros

import ../io
export io  # for open, write,...

macro expLower(sym) =
  var s = sym.strVal
  s[0] = char(s[0].int - 32)
  let toId = ident s
  quote do:
    let `sym`* = $`toId`

expLower curdir 
expLower pardir 
expLower extsep
expLower pathsep
expLower altsep

let
  linesep* = "\p"
  sep* = $DirSep

when defined(windows):
  const
    name* = "nt"
    devnull* = "nul"
    defpath* = ".;C:\\bin"
    
else:
  const
    name* = "posix"
    devnull* = "/dev/null"
    defpath = "/bin:/usr/bin"


proc getcwd*(): string = getCurrentDir()
proc chdir*(s: string) = setCurrentDir s

proc mkdir*(d: string) = createDir d
proc rmdir*(d: string) = removeDir d

## os.path
let path* = (
  curdir: curdir, pardir: pardir, sep: sep,
  pathsep: pathsep, defpath: defpath, extsep: extsep, altsep: altsep,
  devnull: devnull,
  isabs: (proc (s: string): bool = isAbsolute s),
  dirname: (proc (s: string): string = parentDir s),
  join: (proc (v: varargs[string]): string = joinPath v),

)

when defined(nimPreviewSlimSystem):
  import std/syncio

{.push header: "<errno.h>".}
let errno{.importc.}: cint
let EINTR{.importc.}: cint
{.pop.}

const DW = defined(windows)
macro uLexp(i; header: string = "<fcntl.h>") =
  ## POSIX/Windows `importc` and export
  ## add prefix underline when `importc` under Windows
  let
    strv = i.strVal
    cn = '_' & strv
    cnn = newLit cn
  result = quote do:
    let `i`*{.importc: `cnn`, header: `header`.}: cint

macro pwULexp(i; header: string = "<fcntl.h>") =
  ## POSIX/Windows `importc` and export
  ## add prefix underline when `importc` under Windows
  let
    strv = i.strVal
    cn = when DW: '_' & strv else: strv
    cnn = newLit cn
  result = quote do:
    let `i`*{.importc: `cnn`, header: `header`.}: cint

# TODO: export ones that are OS-dependent
#  such as https://docs.python.org/3/library/os.html#os.O_DSYNC
pwULexp O_RDONLY
pwULexp O_WRONLY
pwULexp O_RDWR
pwULexp O_APPEND
pwULexp O_CREAT
pwULexp O_EXCL
pwULexp O_TRUNC

when DW:
  uLexp O_BINARY
  uLexp O_NOINHERIT
else:
  uLexp O_CLOEXEC

template `|`*(a,b: cint): cint = a or b
template `|=`*(a,b: cint) = a = a or b

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
  let O_CLOEXEC{.importc, header: "<fcntl.h>".}: cint

macro fdopen*(fd: Positive; x: varargs[untyped]): untyped =
  ## Return an open file object connected to the file descriptor fd. 
  ## 
  ## This is an alias of the io.open() function and accepts the same arguments.
  ## The only difference is that the first argument of fdopen() must always be an integer.
  runnableExamples:
    const fn = "tempfiletest"
    let fd = open(fn, O_RDWR|O_CREAT)
    var f = fdopen(fd, "w+")
    let s = "123"
    f.write(s)
    f.seek(0)
    let res = f.read()
    f.close()
    assert res == s
  result = newCall(ident"open", fd)
  for i in x:
    result.add i  # support kw (will be of kind: nnkExprEqExpr)

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

