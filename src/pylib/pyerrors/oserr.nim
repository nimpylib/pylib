
when NimMajor > 1:
  import std/oserrors
else:
  import std/os
when defined(windows):
  import std/winlean
else:
  import std/posix

const InJs* = defined(js)
when InJs:
  import ./jsoserr

import ../io_abc
import ../private/backendMark
export OSErrorCode
type
  FileNotFoundError* = object of OSError
  FileExistsError* = object of OSError
  NotADirectoryError* = object of OSError
  IsADirectoryError* = object of OSError

# some error is still defined in ./io.nim
# as they're currently only used there.

const weirdTarget{.used.} = defined(nimscript) or defined(js)
when InJs:
  export isNotFound
elif defined(nimscript):
  proc isNotFound*(err: OSErrorCode): bool{.error: "not implement for NimScript backend".}
else:
  when defined(windows):
    proc isNotFound*(err: OSErrorCode): bool = 
      let i = err.int
      i == ERROR_FILE_NOT_FOUND or i == ERROR_PATH_NOT_FOUND
    const ERROR_DIRECTORY_NOT_SUPPORTED = 336
  else:
    let enoent = ENOENT.int
    proc isNotFound*(err: OSErrorCode): bool = err.int == enoent  

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

when InJs:
  func osErrorMsgWithPath*(fp: PathLike, err: OSErrorCode): string{.error: "not impl".}
    #bind osErrorMsgWithPath, errnoMsgOSErr
    #osErrorMsgWithPath(fp, err, errnoMsgOSErr)
else:
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

template noWeirdTarget*(def) =
  bind noWeirdBackend
  noWeirdBackend(def)

const CONST_E = defined(windows) or compiles(static(EEXIST))
# in posix_other_const.nim, E* is declared as `var`

when defined(nimscript):
  const
    NON_ERR_CODE = -1  # no errCode shall match this
    ErrExist = NON_ERR_CODE
    ErrNoent = NON_ERR_CODE
    ErrIsdir = NON_ERR_CODE
elif InJs: discard
else:

  when defined(windows):
    const
      ERROR_ALREADY_EXISTS = 183
      ErrExist = {ERROR_FILE_EXISTS, ERROR_ALREADY_EXISTS}
      ErrNoent = {ERROR_PATH_NOT_FOUND, ERROR_FILE_NOT_FOUND}
      ErrIsdir = ERROR_DIRECTORY_NOT_SUPPORTED
  elif CONST_E:
    const
      ErrExist = EEXIST
      ErrNoent = ENOENT
      ErrIsdir = EISDIR
  else:
     let
      ErrExist = EEXIST
      ErrNoent = ENOENT
      ErrIsdir = EISDIR


func raiseFileExistsError*(fp: PathLike) =
    fp.raiseExcWithPath(FileExistsError, ErrExist.OSErrorCode)

# symbol used in case stmt's `of` branch must be constants
when CONST_E:
  template errMap(oserr: OSErrorCode, rErr; osErrorMsgCb:typed=osErrorMsg) =
    case system.int(oserr)
    of ErrExist:
      rErr FileExistsError
    of ErrNoent:
      rErr FileNotFoundError
    of ErrIsdir:
      rErr IsADirectoryError
    else:
      raise newOSErrorWithMsg(oserr, osErrorMsgCb(oserr))
else:
  template errMap(oserr: OSErrorCode, rErr; osErrorMsgCb:typed=osErrorMsg) =
    let ierr = oserr.int
    if ierr == ErrExist:
      rErr FileExistsError
    elif ierr == ErrNoent:
      rErr FileNotFoundError
    elif ierr == ErrIsdir:
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

func pathsAsOne*[T](a, b: PathLike[T], sep = " -> "): string =
  ## used when there are two pathes that needs to be reported in error message.
  ## called by `raiseExcWithPath2`_
  a.pathrepr & sep & b.pathrepr

proc raiseExcWithPath2*(src, dst: PathLike) =
  pathsAsOne(src, dst).raiseExcWithPath()

template tryOsOp*(p: PathLike, body) =
  bind raiseExcWithPath
  try: body
  except OSError as e:
    p.raiseExcWithPath(e.errorCode.OSErrorCode)

when InJs:
  proc errnoMsgOSErr(errnoCode: OSErrorCode): string = jsErrnoMsg(errnoCode)
  proc errnoMsg*(errnoCode: cint): string = jsErrnoMsg(errnoCode.OSErrorCode)
elif not weirdTarget:
  proc c_strerror(code: cint): cstring{.importc: "strerror", header: "<string.h>".}

  func errnoMsgOSErr(errnoCode: OSErrorCode): string = $c_strerror(errnoCode.cint)

  func errnoMsg*(errnoCode: cint): string = $c_strerror(errnoCode)


proc newErrnoErrT[E: OSError](errnoCode: cint, additionalInfo = ""): owned(ref E) =
  result = (ref E)(errorCode: errnoCode.int32, msg: errnoMsg(errnoCode))
  if additionalInfo.len > 0:
    if result.msg.len > 0 and result.msg[^1] != '\n': result.msg.add '\n'
    result.msg.add "Additional info: "
    result.msg.add additionalInfo
      # don't add trailing `.` etc, which negatively impacts "jump to file" in IDEs.
  if result.msg == "":
    result.msg = "unknown OS error"
proc newErrnoErr(errnoCode: cint, additionalInfo = ""): owned(ref OSError) =
  newErrnoErrT[OSError](errnoCode, additionalInfo)


proc raiseErrno*(errno: cint; additionalInfo = "") =
  ## may raise OSError only
  raise newErrnoErr(errno, additionalInfo)

proc raiseErrnoWithPath*[T](p: PathLike[T]; errno: cint) =
  ## raises OSError or its SubError.
  ## refer to errno even under Windows.
  let errCode = errno.OSErrorCode
  template rErr(exc) =
    p.raiseExcWithPath(exc, errCode)
  errMap errCode, rErr, errnoMsgOSErr

when InJs:
  proc raiseErrnoWithMsg*(errno: cint, errMsg: string) =
    let errCode = errno.OSErrorCode
    template rErr(exc) =
      raise newException(exc, errMsg)
    template msgDiscardCode(_): string = errMsg
    errMap errCode, rErr, msgDiscardCode
  template catchJsErrAndRaise*(doSth) =
      var errMsg = ""
      let err = catchJsErrAsCode errMsg:
        doSth
      if err != 0:
        raiseErrnoWithMsg err, errMsg
else:
  when not declared(errno):
    var errno{.importc, header: "<errno.h>".}: cint
  proc newErrnoErrT[E: OSError](additionalInfo = ""): owned(ref E) =
    newErrnoErrT[E](errno, additionalInfo)

  proc raiseErrnoT*[E: OSError](additionalInfo = "") =
    ## may raise `E` only
    raise newErrnoErrT[E](additionalInfo)
  proc raiseErrno*(additionalInfo = "") =
    raiseErrnoT[OSError](additionalInfo)

  proc raiseErrnoWithPath*[T](p: PathLike[T]) =
    raiseErrnoWithPath(p)


