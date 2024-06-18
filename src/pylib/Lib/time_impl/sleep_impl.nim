
import std/os as nos
template sleep_neg_raise(s) =
  ## As of 2.1.1, Nim's std/os sleep will deadloop in Windows if `milsecs` is negative.
  if s < 0:
    raise newException(ValueError, "sleep length must be non-negative")

template sleep*(s: int) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise
  sleep_neg_raise(s)
  sleep(milsecs=1000 * s)  # param name based overload
template sleep*(s: float) =
  ## raises ValueError if s < 0
  bind sleep, sleep_neg_raise
  sleep_neg_raise(s)
  sleep(milsecs=int(1000 * s))
