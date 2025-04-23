

import ../common
import ./mkrmdirImpl

import ./pyCfg
import ./chkarg

when not InJS:
  importConfig [
    os
  ]
else:
  template decl(f, val) =
    const `HAVE f` = val
  decl unlinkat, false

proc rmdir*(p: PathLike, dir_fd: int) =
  sys.audit("os.rmdir", p, dir_fd)
  var res: cint
  when HAVE_UNLINKAT:
    var unlinkat_unavailable = false
    if dir_fd != DEFAULT_DIR_FD:
      when HAVE_UNLINKAT_RUNTIME:
        res = unlinkat(dir_fd.cint, cstring $p, AT_REMOVEDIR)
      else:
        unlinkat_unavailable = true
        res = -1
    else:
      rawRemoveDir(p)
  else:
    rawRemoveDir(p)
  when HAVE_UNLINKAT:
    if unlinkat_unavailable:
      argument_unavailable_error("dir_fd")
  if res != 0:
    raiseExcWithPath(p)

proc mkdir*(p: PathLike, mode=0o777, dir_fd: int){.error: "not implement".}

proc rmdir*(path: PathLike) =
  sys.audit("os.rmdir", path, -1)
  rawRemoveDir(path)
proc mkdir*(p: PathLike, mode=0o777) =
  sys.audit("os.mkdir", p, mode, -1)
  rawCreateDir(p, mode)

#[ A version of `mkdir` that does not support `mode` 
proc mkdir*(p: PathLike, mode: int){.error: "not implement".}
let ENOENT{.importc, header: "<errno.h>".}: cint
template isNoEnt(e: int32): bool =
  when defined(windows): e == 3 # ERROR_PATH_NOT_FOUND
  else: e == ENOENT.int32

proc mkdir*(p: PathLike) =
  var exists: bool
  try: exists = existsOrCreateDir $p
  except OSError as e:
    if e.errorCode.isNoEnt: p.raiseFileNotFoundError(e.errCode.OSErrorCode)
    else: raise
  if exists: raiseFileExistsError p
]#

