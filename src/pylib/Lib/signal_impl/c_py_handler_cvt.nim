
import ./[pylifecycle, frames]

proc toCSighandler*(p: PySigHandler): CSigHandler =
  proc (signalnum: cint){.noconv.} =
    let frame = getFrameOrNil(2)
    p(signalnum, frame)


proc toPySighandler*(p: CSigHandler|NimSigHandler): PySigHandler =
  proc (signalnum: int, _: PFrame){.closure.} =
    p(cint signalnum)
