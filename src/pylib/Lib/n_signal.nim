
import ./signal_impl/[
  pynsig, signals
]

let NSIG* = int Py_NSIG
export signals

when defined(unix):
  import ./signal_impl/unixs
  export unixs


#proc getsignal*(signalnum: int): int =
when isMainModule:
  signal(1, SIG_IGN)
