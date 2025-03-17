
from std/math import isNaN
import ./[types, rounds, exc_util, units]

using round: PyTime_round_t
using t: PyTime
using tp: var PyTime

proc from_float(tp; value: float, round; unit_to_ns: int) =
  ## pytime_from_double
  # volatile avoids optimization changing how numbers are rounded
  var d{.volatile.}: float

  # convert to a number of nanoseconds
  d = value
  d *= float unit_to_ns
  d = round(d, round)

  # See comments in `float_to_denominator`
  if not ( PyTime.low.float <= d  and d < -PyTime.high.float):
    tp = 0
    time_t_overflow()
  tp = Pytime d

proc from_object(tp; obj: Timestamp, round; unit_to_ns: int) =
  ## pytime_from_object
  when obj is SomeFloat:
    if isNaN(obj):
      raise newException(ValueError, "Invalid value NaN (not a number)")
    tp.from_float(obj, round, unit_to_ns)
  else:
    let ns = PyTime obj
    ns *= PyTime unit_to_ns
    tp = ns

proc fromSecondsObject*(tp; obj: Timestamp; round) =
  ## _PyTime_FromSecondsObject
  tp.from_object(obj, round, SEC_TO_NS)
