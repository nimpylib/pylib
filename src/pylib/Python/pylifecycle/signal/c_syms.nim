
import ../../../pyconfig/signal
export signal
const
  HAVE_BROKEN_PTHREAD_SIGMASK* = defined(cygwin) # XXX: cygwin not supported
  PYPTHREAD_SIGMASK* = HAVE_PTHREAD_SIGMASK and not HAVE_BROKEN_PTHREAD_SIGMASK
  HAVE_SIGSET_T* = PYPTHREAD_SIGMASK or HAVE_SIGWAIT or
    HAVE_SIGWAITINFO or HAVE_SIGTIMEDWAIT

when defined(windows):
  import std/winlean
  export winlean
  import ./handler_types
  template sig(sym) =
    let sym*{.importc, header: "<signal.h>".}: cint

  sig SIGBREAK
  sig SIGABRT
  sig SIGFPE
  sig SIGILL
  sig SIGINT
  sig SIGSEGV
  sig SIGTERM
  let
    CTRL_C_EVENT*{.importc, header: "<Windows.h>".}: cint
    CTRL_BREAK_EVENT*{.importc, header: "<Windows.h>".}: cint
  let
    SIG_DFL*{.importc, header: "<signal.h>".}: CSighandler
    SIG_IGN*{.importc, header: "<signal.h>".}: CSighandler
    SIG_ERR*{.importc, header: "<signal.h>".}: CSighandler
else:
  import std/posix except EINTR, ERANGE
  export posix except EINTR, ERANGE
  let
    ITIMER_REAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_VIRTUAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_PROF*{.importc, header: "<sys/time.h>".}: cint

import ./handler_types


when HAVE_SIGACTION:
  proc sigaction*(a1: cint; a2: ptr Sigaction; a3: var Sigaction): cint{.importc: "sigaction", header: "<sys/signal.h>".}
  ## XXX: posix/winlean's a2 cannot be nil (a var Sigaction)

proc c_signal*(a1: cint, a2: CSighandler): CSighandler {.
  importc: "signal", header: "<signal.h>".}  # XXX: std/posix's lacks restype

