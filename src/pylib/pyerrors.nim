
from std/os import OSErrorCode
export OSErrorCode
type
  FileNotFoundError* = object of OSError

# some error is still defined in ./io.nim
# as they're currently only used there.

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


func raiseFileNotFoundError*(fp: string) =
    raise newException(FileNotFoundError,
        "No such file or directory: "&fp)
