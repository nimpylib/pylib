
import ./pynsig

func chkSigRng*(signalnum: cint|int) =
  if signalnum < 1 or signalnum >= Py_NSIG:
    raise newException(ValueError, "signal number out of range")
