
# import Timeval
const DWin = defined(windows)
when DWin:
  import std/winlean
else:
  import std/posix

import ./[types, ops, units, exc_util]

const
  BAD = false  ## -1 in CPython
  GOOD = true  ## 0 in CPython
type Status = bool


using round: PyTime_round_t
using t: PyTime

proc asTimeval(ns: PyTime, tv_sec: var PyTime, tv_usec: var int, round): Status =
  ## pytime_as_timeval
  let us = divide(ns, PyTime US_TO_NS, round)

  var ttv_usec: PyTime
  result = divmod(us, SEC_TO_US, tv_sec, ttv_usec)
  tv_usec = cast[int](ttv_usec)  # won't overflow

proc asT[T](t; t2: var T): Status =
  when sizeof(T) < sizeof(PyTime):
    if PyTime(high T) < t:
      t2 = high T
      return BAD
    if t < PyTime(low T):
      t2 = low T
      return BAD
  t2 = cast[T](t)
  return GOOD

proc as_timeval_struct(t; round; raise_exc: bool): Timeval =
  var
    tv_sec: PyTime
    tv_usec: int
  let
    res = t.asTimeval(tv_sec, tv_usec, round)
    res2 =
      when DWin:
        tv_sec.asT[:long](result.tv_sec)
      else:
        tv_sec.asT[:Time](result.tv_sec)
  if res2 == BAD:
    tv_usec = 0
  result.tv_usec = tv_usec

  if raise_exc and (res == BAD or res2 == BAD):
    time_t_overflow()


proc asTimeval*(t; round): Timeval =
  ## _PyTime_AsTimeval
  t.as_timeval_struct(round, true)
