
type PySigHandler* = proc (signalnum: int, frame: PFrame){.closure.}

type CSighandler* = proc (signalnum: cint) {.noconv.}  ## PyOS_sighandler_t
