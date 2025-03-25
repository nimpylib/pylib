
import std/sets

import ./[
  errutil,
  c_api,
  chk_util,
  pylifecycle,
  sigsetCvt,
  sigset_to_set,
  siginfo_decl
]
export Sigset
export siginfo_decl except fill_siginfo
import ../../Python/pytime/[deadline, pytimeFromSeconds, pytimeAsTimeval]

proc alarm*(seconds: int): int = int alarm seconds.cint
proc pause*(): int = int posix.pause()

proc pthread_kill*(thread_id: uint, signalnum: int) =
  let err = pthread_kill(Pthread thread_id, cint signalnum)
  if err != 0:
    raiseErrno()

  PyErr_CheckSignalsAndRaises()

type
  Set[T] = HashSet[T]

converter toSigset*(oa: openArray[int]): Sigset = result.fromIterable oa


template markVar(sym) =
  var sym = sym

proc pthread_sigmask*(how: int, mask: Sigset): Set[int] =
  var previous: Sigset
  markVar mask
  let err = pthread_sigmask(how.cint, mask, previous)
  if err != 0:
    raiseErrno err
  PyErr_CheckSignalsAndRaises()
  sigset_to_set(previous)

type ItimerVal*{.importc: "struct itimerval", header: "<sys/time.h>".} = object
  it_interval, it_value: Timeval
type ItimerWhich = cint  # enum
proc setitimer(which: ItimerWhich, `new`, old: ItimerVal): cint {.importc, header: "<sys/header.h>".}
proc getitimer(which: ItimerWhich, old: ItimerVal): cint {.importc, header: "<sys/header.h>".}

func toFloat(tv: Timeval): float =
  tv.tv_sec.float + tv.tv_usec.float / 1_000_000.0

proc itimer_retval(old: ItimerVal): tuple[delay, interval: float] =
  (old.it_value.toFloat, old.it_interval.toFloat)

proc toTimeval(obj: float): Timeval =
  ## timeval_from_double
  var t: PyTime
  t.fromSecondsObject(obj, prCeiling)
  t.asTimeval(prCeiling)

type ItimerError* = object of OSError

proc setitimer*(which: int, seconds: float; interval=0.0): tuple[delay, interval: float] =
  var n: ItimerVal  
  n.it_value = seconds.toTimeval
  n.it_interval = interval.toTimeval
  var old: ItimerVal
  if setitimer(which.cint, n, old) != 0:
    raiseErrnoT[ItimerError]()
  itimer_retval old

proc getitimer*(which: int): tuple[delay, interval: float] =
  var old: ItimerVal
  if getitimer(which.cint, old) != 0:
    raiseErrnoT[ItimerError]()
  
  itimer_retval old


proc siginterrupt*(signalnum, flag: int) =
  let csignalnum = cint signalnum
  csignalnum.chkSigRng
  when HAVE_SIGACTION:
    var act: Sigaction
    discard sigaction(csignalnum, nil, act)
    if flag != 0:
      act.sa_flags = act.sa_flags and not SA_RESTART
    else:
      act.sa_flags = act.sa_flags or SA_RESTART
    if sigaction(csignalnum, act, nil) < 0:
      raiseErrno()
  else:
    if siginterrupt(csignalnum, flag.cint) < 0:
      raiseErrno()


proc sigpending*(): Set[int] =
  var mask: Sigset
  if 0 != sigpending(mask):
    raiseErrno()
  sigset_to_set mask 

proc sigwait*(sigset: Sigset): int =
  var signum: cint
  markVar sigset
  let err = sigwait(sigset, signum)
  if err != 0:
    raiseErrno err

proc sigwaitinfo*(sigset: Sigset): struct_siginfo =
  var err: cint
  var si: SigInfo
  var async_err = 0
  markVar sigset
  while true:
    err = sigwaitinfo(sigset, si)
    if err == -1 and isErr(EINTR) and (
      (async_err = PyErr_CheckSignals(); async_err == 0)
    ):
      continue
    break
  if err == -1:
    #if async_err == 0: 
      raiseErrno()

  fill_siginfo(si)

proc PyTime_AsTimespec(x: TimeStamp): Timespec =
  x.nPyTime_ObjectToTimeval(result.tv_sec, result.tv_usec, prCeiling)

proc sigtimedwait*(sigset: Sigset, timeout: TimeStamp): struct_siginfo =
  var si: SigInfo
  markVar sigset
  var to: PyTime
  to.fromSecondsObject(timeout, prCeiling)
  if to < 0:
    raise newException(ValueError, "timeout must be non-negative")

  let deadline = PyDeadline_Init(to)
  var si: SigInfo

  while true:
    var ts = PyTime_AsTimespec timeout
    let res = sigtimedwait(sigset, si, ts)

    if res != -1:
      break

    if not isErr EINTR:
      if isErr ERANGE:
        return
      raiseErrno()
    
    # sigtimedwait() was interrupted by a signal (EINTR)
    PyErr_CheckSignalsAndRaises()

    timeout = PyDeadline_Get(deadline)
    if timeout < 0:
      break
  
  fill_siginfo(si)
