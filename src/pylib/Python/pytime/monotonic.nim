
import std/monotimes
import ./types

template py_get_monotonic(tp: var PyTime): bool =
  ## py_get_monotonic(res, NULL, 1)
  tp = getMonoTime().ticks
  true

proc monotonicRaw*(res: var PyTime): bool =
  if not py_get_monotonic(res):
    res = 0
  return true

