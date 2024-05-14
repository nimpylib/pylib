
when defined(windows):
  import std/winlean
else:
  import std/posix

from std/os import OSErrorCode
import ./io_abc
export OSErrorCode
type
  FileNotFoundError* = object of OSError
  FileExistsError* = object of OSError
  TypeError* = object of CatchableError

# some error is still defined in ./io.nim
# as they're currently only used there.

when not defined(js):
  when defined(windows):
    proc isNotFound*(err: OSErrorCode): bool = 
      let i = err.int
      i == ERROR_FILE_NOT_FOUND or i == ERROR_PATH_NOT_FOUND
  else:
    let enoent = ENOENT.int
    proc isNotFound*(err: OSErrorCode): bool = err.int == enoent
else:
  proc isNotFound*(err: OSErrorCode): bool{.error: "not implement for JS backend".}

func raiseFileNotFoundError*(fp: PathLike) =
    raise newException(FileNotFoundError,
        "No such file or directory: " & fp.pathrepr)

func raiseFileExistsError*(fp: PathLike) =
    raise newException(FileExistsError,
        " file or directory exists: " & fp.pathrepr)
    # XXX: not the same as Py's...
