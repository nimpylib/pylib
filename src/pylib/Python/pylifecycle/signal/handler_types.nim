
type
  PySigHandler* = proc (signalnum: int, frame: PFrame){.closure.}
  CSigHandler* = proc (signalnum: cint) {.noconv.}  ## PyOS_sighandler_t
  NimSigHandler* = proc (signalnum: int){.nimcall.}
