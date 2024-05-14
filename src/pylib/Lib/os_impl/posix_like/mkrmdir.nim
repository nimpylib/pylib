

import ../common
import ./mkrmdirImpl

proc mkdir*(p: PathLike, mode=0o777, dir_fd: int){.error: "not implement".}
proc rmdir*(p: PathLike, dir_fd: int){.error: "not implement".}

proc rmdir*(path: PathLike) = rawRemoveDir(path)
proc mkdir*(p: PathLike, mode=0o777) = rawCreateDir(p, mode)

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

