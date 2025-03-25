
import ./pylifecycle

proc toCSighandler*(p: PySighandler): CSigHandler =
  proc (signalnum: cint){.noconv.} =
    let frame = getFrame() #  this closure's
    p(signalnum, frame.prev.prev)


proc toPySighandler*(p: CSighandler): PySigHandler =
  proc (signalnum: int, _: PFrame){.closure.} =
    p(cint signalnum)
