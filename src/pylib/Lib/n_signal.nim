
import std/sets
import ./signal_impl/[
  pynsig, signals, signal_util, valid_signals_impl, enums
]

let NSIG* = int Py_NSIG
export signals, signal_util, enums
export SIG_DFL, SIG_IGN

import ./signal_impl/unixs
export unixs

proc valid_signals*(): HashSet[int] =
  result = initHashSet[int]()
  result.fill_valid_signals()

#proc getsignal*(signalnum: int): int =
when isMainModule:
  signal(1, SIG_IGN)
