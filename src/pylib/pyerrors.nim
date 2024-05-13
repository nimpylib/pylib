
from std/os import OSErrorCode
import ./io_abc
export OSErrorCode
type
  FileNotFoundError* = object of OSError
  TypeError* = object of CatchableError

# some error is still defined in ./io.nim
# as they're currently only used there.

when not defined(js):
  when defined(windows):
    let enoent = 2
    let ERROR_PATH_NOT_FOUND = 3
    proc isNotFound*(err: OSErrorCode): bool = 
      let i = err.int
      i == enoent or i == ERROR_PATH_NOT_FOUND
  else:
    let ENOENT{.importc, header: "<errno.h>".}: cint
    let enoent = ENOENT.int
    proc isNotFound*(err: OSErrorCode): bool = err.int == enoent
else:
  proc isNotFound*(err: OSErrorCode): bool{.error: "not implement for JS backend".}

func raiseFileNotFoundError*(fp: PathLike) =
    raise newException(FileNotFoundError,
        "No such file or directory: " & fp.pathrepr)

