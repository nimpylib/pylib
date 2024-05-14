
when defined(windows):
  import std/winlean
else:
  import std/posix

when NimMajor > 1:
  import std/oserrors
else:
  import std/os
import ./io_abc
export OSErrorCode
type
  FileNotFoundError* = object of OSError
  FileExistsError* = object of OSError
  NotADirectoryError* = object of OSError
  IsADirectoryError* = object of OSError
  TypeError* = object of CatchableError

# some error is still defined in ./io.nim
# as they're currently only used there.

when not defined(js):
  when defined(windows):
    proc isNotFound*(err: OSErrorCode): bool = 
      let i = err.int
      i == ERROR_FILE_NOT_FOUND or i == ERROR_PATH_NOT_FOUND
    const ERROR_DIRECTORY_NOT_SUPPORTED = 336
  else:
    let enoent = ENOENT.int
    proc isNotFound*(err: OSErrorCode): bool = err.int == enoent
else:
  proc isNotFound*(err: OSErrorCode): bool{.error: "not implement for JS backend".}

func osErrorMsgWithPath*(fp: PathLike, err: OSErrorCode): string =
  ## always suffixed with a `\n`
  var msg = osErrorMsg(err)
  if msg == "":
    msg = "unknown OS error"
  let noNL = msg.len > 0 and msg[^1] != '\n'
  if not noNL:
    msg.setLen msg.len - 1
    msg.add ": "
  msg.add fp.pathrepr & '\n'
  msg

func raiseExcWithPath*(fp: PathLike, exc: typedesc, err: OSErrorCode) =
  raise newException(exc, fp.osErrorMsgWithPath(err))

func raiseExcWithPath*(fp: PathLike, exc: typedesc, err: OSErrorCode, additionalInfo: string) =
  var msg = fp.osErrorMsgWithPath(err)
  msg.add "Additional info: "
  msg.add additionalInfo
  raise newException(exc, msg)

func raiseFileNotFoundError*(fp: PathLike) =
  ## with static msg: "No such file or directory"
  raise newException(FileNotFoundError, 
      "No such file or directory: " & fp.pathrepr)

func raiseFileNotFoundError*(fp: PathLike, err: OSErrorCode) =
  ## under Windows, both ERROR_FILE_NOT_FOUND and ERROR_PATH_NOT_FOUND
  ## lead to FileNotFoundError, at pass `err` to distinguish them
  fp.raiseExcWithPath(FileNotFoundError, err)

when defined(windows):
  const
    ErrExist = ERROR_FILE_EXISTS
    ErrNoent = {ERROR_PATH_NOT_FOUND, ERROR_FILE_NOT_FOUND}
    ErrIsdir = ERROR_DIRECTORY_NOT_SUPPORTED
else:
  const
    ErrExist = EEXIST
    ErrNoent = ENOENT
    ErrIsdir = EISDIR

func raiseFileExistsError*(fp: PathLike) =
    fp.raiseExcWithPath(FileExistsError, ErrExist.OSErrorCode)

template errMap(oserr: OSErrorCode, rErr) =
  case oserr.int
  of ErrExist:
    rErr FileExistsError
  of ErrNoent:
    rErr FileNotFoundError
  of ErrIsdir:
    rErr IsADirectoryError
  else:
    raiseOSError(oserr)

func raiseExcWithPath*(p: PathLike, errCode: OSErrorCode) =
  ## raises OSError or its one of SubError type
  template rErr(exc) =
    p.raiseExcWithPath(exc, errCode)
  errMap errCode, rErr

func raiseExcWithPath*(p: PathLike) =
  let oserr = osLastError()
  p.raiseExcWithPath(oserr)
