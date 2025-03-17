
from std/math import round, ceil, floor
import ./types

func round_half_even*(x: float): float =
  result = round(x)
  if abs(x-result) == 0.5:
    # halfway case: round to even
    result = 2.0 * round(x / 2.0)

func round*(x: float, round: PyTime_round_t): float =
  var d{.volatile.}: float

  d = case round
    of prHalfEven: round_half_even(x)
    of prCeiling: ceil(x)
    of prFLoor: floor(x)
    of prRoundUp: (if x >= 0: ceil(x) else: floor(x))
  return d