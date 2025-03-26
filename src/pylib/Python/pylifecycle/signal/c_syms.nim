
when defined(windows):
  import std/winlean
  export winlean
  let SIGBREAK*{.importc, header: "<signal.h>".}: cint
  proc sigismember*(a1: var Sigset, a2: cint): cint {.importc, header: "<signal.h>".}
else:
  import std/posix except EINTR, ERANGE
  export posix except EINTR, ERANGE
  let
    ITIMER_REAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_VIRTUAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_PROF*{.importc, header: "<sys/time.h>".}: cint

import ./handler_types

const HAVE_SIGACTION* = declared(sigaction)
when HAVE_SIGACTION:
  proc sigaction*(a1: cint; a2: ptr Sigaction; a3: var Sigaction): cint{.importc: "sigaction", header: "<sys/signal.h>".}
  ## XXX: posix/winlean's a2 cannot be nil (a var Sigaction)

proc c_signal*(a1: cint, a2: CSighandler): CSighandler {.
  importc: "signal", header: "<signal.h>".}  # XXX: std/posix's lacks restype

