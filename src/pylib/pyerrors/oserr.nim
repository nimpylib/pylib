
when defined(windows):
  import std/winlean
else:
  import std/posix

when NimMajor > 1:
  import std/oserrors
else:
  import std/os
import ../io_abc
export OSErrorCode
type
  FileNotFoundError* = object of OSError
  FileExistsError* = object of OSError
  NotADirectoryError* = object of OSError
  IsADirectoryError* = object of OSError

# some error is still defined in ./io.nim
# as they're currently only used there.

const weirdTarget = defined(nimscript) or defined(js)
when not weirdTarget:
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

template osErrorMsgWithPath*(fp: PathLike, err: OSErrorCode, osErrorMsgCb): string =
  ## always suffixed with a `\n`
  var msg = osErrorMsgCb(err)
  if msg == "":
    msg = "unknown OS error"
  if msg.len > 0 and msg[^1] != '\n':
    msg.setLen msg.len - 1
    msg.add ": "
  msg.add fp.pathrepr
  msg

template osErrorMsgWithPath*(fp: PathLike, err: OSErrorCode): string =
  bind osErrorMsgWithPath, osErrorMsg
  osErrorMsgWithPath(fp, err, osErrorMsg)

func newOSErrorWithMsg(err: OSErrorCode, msg: string): owned(ref OSError) =
  (ref OSError)(errorCode: err.int32, msg: msg)

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

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}
when weirdTarget:
    const
      NON_ERR_CODE = -1  # no errCode shall match this
      ErrExist = NON_ERR_CODE
      ErrNoent = NON_ERR_CODE
      ErrIsdir = NON_ERR_CODE
else:
  when defined(windows):
    const
      ERROR_ALREADY_EXISTS = 183
      ErrExist = {ERROR_FILE_EXISTS, ERROR_ALREADY_EXISTS}
      ErrNoent = {ERROR_PATH_NOT_FOUND, ERROR_FILE_NOT_FOUND}
      ErrIsdir = ERROR_DIRECTORY_NOT_SUPPORTED
  else:
    const
      ErrExist = EEXIST
      ErrNoent = ENOENT
      ErrIsdir = EISDIR

func raiseFileExistsError*(fp: PathLike) =
    fp.raiseExcWithPath(FileExistsError, ErrExist.OSErrorCode)

template errMap(oserr: OSErrorCode, rErr; osErrorMsgCb=osErrorMsg) =
  case oserr.int
  of ErrExist:
    rErr FileExistsError
  of ErrNoent:
    rErr FileNotFoundError
  of ErrIsdir:
    rErr IsADirectoryError
  else:
    raise newOSErrorWithMsg(oserr, osErrorMsgCb(oserr))

proc raiseExcWithPath*(p: PathLike, errCode: OSErrorCode){.sideEffect.} =
  ## raises OSError or its one of SubError type
  template rErr(exc) =
    p.raiseExcWithPath(exc, errCode)
  errMap errCode, rErr

proc raiseExcWithPath*(p: PathLike){.sideEffect.} =
  let oserr = osLastError()
  p.raiseExcWithPath(oserr)

template tryOsOp*(p: PathLike, body) =
  bind raiseExcWithPath
  try: body
  except OSError as e:
    p.raiseExcWithPath(e.errorCode.OSErrorCode)

when defined(windows):
  # std/posix has defined `errno`
  var errno{.importc, header: "<errno.h>".}: cint

when not weirdTarget:
  proc c_strerror(code: cint): cstring{.importc: "strerror", header: "<string.h>".}

  func errnoMsgOSErr(errnoCode: OSErrorCode): string = $c_strerror(errnoCode.cint)

  func errnoMsg*(errnoCode: cint): string = $c_strerror(errnoCode)

  proc newErrnoErr(errnoCode: cint, additionalInfo = ""): owned(ref OSError) =
    result = (ref OSError)(errorCode: errnoCode.int32, msg: errnoMsg(errno))
    if additionalInfo.len > 0:
      if result.msg.len > 0 and result.msg[^1] != '\n': result.msg.add '\n'
      result.msg.add "Additional info: "
      result.msg.add additionalInfo
        # don't add trailing `.` etc, which negatively impacts "jump to file" in IDEs.
    if result.msg == "":
      result.msg = "unknown OS error"

  proc newErrnoErr(additionalInfo = ""): owned(ref OSError) =
    newErrnoErr(errno, additionalInfo)

  proc raiseErrno*(additionalInfo = "") =
    ## may raise OSError only
    raise newErrnoErr(additionalInfo)

  proc raiseErrnoWithPath*[T](p: PathLike[T]) =
    ## raises OSError or its SubError.
    ## refer to errno even under Windows.
    let errCode = errno.OSErrorCode
    template rErr(exc) =
      p.raiseExcWithPath(exc, errCode)
    errMap errCode, rErr, errnoMsgOSErr
