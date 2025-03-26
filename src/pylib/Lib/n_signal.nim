
import std/sets
import ./signal_impl/[
  pynsig, signals, signal_util, valid_signals_impl
]

let NSIG* = int Py_NSIG
export signals, signal_util

when defined(unix):
  import ./signal_impl/unixs
  export unixs

proc valid_signals*(): HashSet[int] =
  result = initHashSet[int]()
  result.fill_valid_signals()

#proc getsignal*(signalnum: int): int =
when isMainModule:
  signal(1, SIG_IGN)
