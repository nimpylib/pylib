
from ./inner_consts import MINYEAR, MAXYEAR
from ./calendar_utils import ymd_to_ord
import ./time_utils, ./struct_tm_helper

let max_fold_seconds* = BiggestInt 24 * 3600  ## \
## As of version 2015f max fold in IANA database is
## 23 hours at 1969-09-30 13:00:00 in Kwajalein.

let epoch* = BiggestInt(719163) * 24 * 60 * 60  ## \
## NB: date(1970,1,1).toordinal() == 719163

func utc_to_seconds*(year, month, day, hour, minute, second: int): BiggestInt =
  if year < MINYEAR or year > MAXYEAR:
    raise newException(ValueError, "year " & $year & " is out of range")
  
  let ordinal = BiggestInt ymd_to_ord(year, month, day)
  return ((ordinal * 24 + hour) * 60 + minute) * 60 + second

proc local*(u: BiggestInt): BiggestInt =
  ## never returns -1, unlike CPython,
  ## but may raises OverflowDefect
  let t = time_t(u - epoch)
  # here Nim will handle overflow
  let local_time = nTime_localtime(t)
  return cTmToNormCall(utc_to_seconds, local_time)

proc local_to_seconds*(year, month, day, hour, minute, second: int, fold: int): BiggestInt =
  ## never returns -1, unlike CPython,
  ## but may raises OverflowDefect
  let t = utc_to_seconds(year, month, day, hour, minute, second)
  var lt = local(t)
  template invalRet(t) =
    #if t == -1: return -1
    # do nothing, as `local` won't return -1
    discard
  invalRet lt
  let
    a = lt - t
    u1 = t - a
    t1 = local(u1)
  invalRet t1
  var
    u2, b: BiggestInt
  if t1 == t:
    #[ We found one solution, but it may not be the one we need.
       Look for an earlier solution (if `fold` is 0), or a
       later one (if `fold` is 1). ]#
    if bool(fold):
      u2 = u1 + max_fold_seconds
    else:
      u2 = u1 - max_fold_seconds
    lt = local(u2)
    invalRet lt
    b = lt - u2
    if a == b:
      return u1
  else:
    b = t1 - u1
    assert a != b
  u2 = t - b
  let t2 = local(u2)
  invalRet t2
  if t2 == t:
    return u2
  if t1 == t:
    return u1
  
  #[ We have found both offsets a and b, but neither t - a nor t - b is
     a solution.  This means t is in the gap. ]#
  return if bool(fold): min(u1, u2) else: max(u1, u2)
