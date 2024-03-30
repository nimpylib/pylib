
import std/os

import std/macros

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
