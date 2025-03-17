
import ./types


proc iadd*(t1: var PyTime, t2: PyTime): bool =
  ## pytime_add
  if t2 > 0 and t1 > PyTime.high - t2:
    t1 = PyTime.high
    false
  elif t2 < 0 and t1 < PyTime.low - t2:
    t1 = PyTime.low
    false
  else:
    t1 += t2
    true

proc add*(t1, t2: PyTime): PyTime =
  ## `_PyTime_Add`
  result = t1
  discard result.iadd t2

proc divide_round_up*(t, k: PyTime): PyTime =
  assert k > 1
  # Don't use (t +- k - 1) / k to avoid integer overflow
  # if t is equal to PyTime_{MAX,MIN}
  result = t div k
  if t mod k != 0:
    if t >= 0:
      result.inc
    else:
      result.dec


proc divide*(t, k: PyTime, round: PyTime_round_t): PyTime =
  assert k > 1
  template retNNegOr(a, b) =
    if t >= 0: return a
    else: return b
  case round
  of prHalfEven:
    result = t div k
    let
      r = t mod k
      abs_r = abs(r)
      k2 = k div 2
    if abs_r > k2 or (abs_r == k2 and (abs(result) and 1) == 1):
      if t >= 0: result.inc
      else: result.dec
  of prCeiling:
    retNNegOr divide_round_up(t, k), t div k
  of prFloor:
    retNNegOr t div k, divide_round_up(t, k)
  else:
    result = divide_round_up(t, k)

proc divmod*(t, k: PyTime, pq, pr: var PyTime): bool =
  assert k > 1
  var
    q = t div k
    r = t mod k
  if r < 0:
    if q == low PyTime:
      pq = low PyTime
      pr = 0
      return false
    r.inc k
    q.dec
  assert 0 <= r and r < k

  pq = q
  pr = r
  return true

