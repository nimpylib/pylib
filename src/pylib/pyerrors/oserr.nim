##[
See CPython's Objects/exceptions.c

`OSError_new`(a.k.a. `OSError.__new__`) will returns a subclass of OSError,
via lookup in `state->errnomap`, which is initialized by `_PyExc_InitState`,

where key-value pairs are inserted via `ADD_ERRNO` macro.
]##
when NimMajor > 1:
  import std/oserrors
else:
  import std/os
when defined(windows):
  import std/winlean
else:
  import std/posix

const InJs = defined(js)
when InJs:
  import ./jsoserr

import ../io_abc
import ../private/backendMark
import ../Lib/errno_impl/errnoUtils
export OSErrorCode
import ./oserr/[
  types as oserrors_types, errmap, oserror_new, init as oserrors_init, oserror_str
]
export oserrors_types, oserror_str, oserrors_init
when defined(windows):
  import ./oserr/PC_errmap


const weirdTarget{.used.} = defined(nimscript) or defined(js)

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

proc raiseExcWithPath*(fp: PathLike, exc: typedesc, err: OSErrorCode,
    osErrorMsgCb: proc = osErrorMsg) =
  raise newException(exc, fp.osErrorMsgWithPath(err, osErrorMsgCb))

func raiseExcWithPath*(fp: PathLike, exc: typedesc, err: OSErrorCode, additionalInfo: string) =
  var msg = fp.osErrorMsgWithPath(err)
  msg.add "Additional info: "
  msg.add additionalInfo
  raise newException(exc, msg)

template noWeirdTarget*(def) =
  bind noWeirdBackend
  noWeirdBackend(def)


proc raiseExcWithPath*(p: PathLike, errCode: OSErrorCode){.sideEffect.} =
  ## raises OSError or its one of SubError type
  raise OSError_new[oserrors_types.PyOSError](true, errCode.cint, p.fspath)

proc raiseExcWithPath*(p: PathLike){.sideEffect.} =
  let oserr = osLastError()
  p.raiseExcWithPath(oserr)

func pathsAsOne[T](a, b: PathLike[T], sep = " -> "): string =
  ## used when there are two pathes that needs to be reported in error message.
  ## called by `raiseExcWithPath2`_
  a.pathrepr & sep & b.pathrepr

proc raiseExcWithPath2*(src, dst: PathLike) =
  pathsAsOne(src, dst).raiseExcWithPath()

template tryOsOpAux(body, excHandleBody){.dirty.} =
  bind raiseExcWithPath
  try: body
  except OSError as e:
    excHandleBody

template tryOsOp*(p: PathLike, body) =
  bind tryOsOpAux
  tryOsOpAux(body):
    p.raiseExcWithPath(e.errorCode.OSErrorCode)

template tryOsOp*(p: PathLike, raiseCond: bool, body) =
  bind raiseExcWithPath
  tryOsOpAux(body):
    if raiseCond:
      p.raiseExcWithPath(e.errorCode.OSErrorCode)

template tryOsOp*(raiseCond: bool, body) =
  bind raiseExcWithPath
  tryOsOpAux(body):
    if raiseCond:
      raise newPyOSError(e.errorCode.cint, e.msg)

template tryOsOp*(p1, p2: PathLike, body) =
  bind pathsAsOne
  pathsAsOne(p1, p2).tryOsOp body

when InJs:
  proc errnoMsg*(errno: cint): string = jsErrnoMsg(errno.OSErrorCode)
elif not weirdTarget:
  proc c_strerror(code: cint): cstring{.importc: "strerror", header: "<string.h>".}

  func errnoMsg*(errno: cint): string = $c_strerror(errno)

proc newErrnoErrT[E: PyOSError](errno=getErrno(), strerr: string): owned(ref PyOSError) =
  OSError_new[E](false, errno, strerr)
proc newErrnoErrT[E: PyOSError](errno=getErrno()): owned(ref PyOSError) =
  newErrnoErrT[E](errno, errnoMsg(errno))

proc newErrnoErr(errno=getErrno()): owned(ref PyOSError) =
  newErrnoErrT[oserrors_types.PyOSError](errno)

proc raiseErrno*(errno=getErrno()) =
  ## may raise subclass of OSError
  raise newErrnoErr(errno)

proc raiseErrnoT*[T: PyOSError](errno=getErrno()) =
  raise newErrnoErrT[T](errno)

proc raiseErrnoWithPath*[T](p: PathLike[T]; errno = getErrno()) =
  ## raises OSError or its SubError.
  ## refer to errno even under Windows.
  raise OSError_new[oserrors_types.PyOSError](false, errno, errnoMsg(errno), p.fspath)

when InJs:
  proc raiseErrnoWithMsg*(errno: cint, errMsg: string) =
    raise OSError_new[oserrors_types.PyOSError](false, errno, errMsg, fillMsg=false)

  template catchJsErrAndDo(doSth; doErr) =
      var errMsg = ""
      let err = catchJsErrAsCode errMsg:
        doSth
      if err != 0: doErr err, errMsg
  template catchJsErrAndRaise*(doSth) =
    bind catchJsErrAndDo, raiseErrnoWithMsg
    template doErr(err, errMsg) =
      raiseErrnoWithMsg err, errMsg
    catchJsErrAndDo doSth, doErr

  template catchJsErrAndSetErrno*(doSth) =
    bind catchJsErrAndDo, setErrnoRaw
    template doErr(err, errMsg) =
      setErrnoRaw err
    catchJsErrAndDo doSth, doErr


