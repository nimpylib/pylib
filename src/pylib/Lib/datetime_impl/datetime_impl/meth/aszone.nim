
import std/macros

include ./common
import ../../../../Python/unicodeobject/locale_codec

import ../../timedelta_impl/[decl, meth]
import ../../timezone_impl/[decl, meth_by_datetime_getter, meth_by_datetime]

from ./importer import ymd_to_ord
import ./time_utils
import ./inner_consts
import ./init, ./op

macro cTmToNormCall(call; tm: Tm; kwargs: varargs[untyped]): untyped =
  result = quote do:
    `call`(
        `tm`.tm_year + 1900,
        `tm`.tm_mon + 1,
        `tm`.tm_mday,
        `tm`.tm_hour,
        `tm`.tm_min,
        `tm`.tm_sec,)
  for i in kwargs:
    result.add i

## As of version 2015f max fold in IANA database is
## 23 hours at 1969-09-30 13:00:00 in Kwajalein.
let max_fold_seconds = 24 * 3600

## NB: date(1970,1,1).toordinal() == 719163
let epoch = BiggestInt 719163 * 24 * 60 * 60

func utc_to_seconds(year, month, day, hour, minute, second: int): BiggestInt =
  if year < MINYEAR or year > MAXYEAR:
    raise newException(ValueError, "year " & $year & " is out of range")
  
  let ordinal = BiggestInt ymd_to_ord(year, month, day)
  return ((ordinal * 24 + hour) * 60 + minute) * 60 + second

proc local(u: BiggestInt): BiggestInt =
  ## never returns -1, unlike CPython,
  ## but may raises OverflowDefect
  let t = time_t(u - epoch)
  # here Nim will handle overflow
  let local_time = nTime_localtime(t)
  return cTmToNormCall(utc_to_seconds, local_time)

proc local_to_seconds(year, month, day, hour, minute, second: int, fold: int): BiggestInt =
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

proc newDatetime(tm: Tm): datetime =
  cTmToNormCall(datetime, tm, fold=0)

proc getUtcOffset(local_time_tm: Tm, timestamp: time_t): timedelta =
  ## `local_time_tm` shall be getten via `localtime` with `timestamp` as arg
  when HAVE_STRUCT_TM_TM_ZONE: 
    result = newTimedelta(0, local_time_tm.tm_gmtoff, 0, true)
  else:
    let local_time = newDatetime(local_time_tm)
    let utc_time_tm = nTime_gmtime(timestamp)
    let utc_time = newDatetime(utc_time_tm)
    result = local_time - utc_time

proc local_timezone_from_timestamp(timestamp: time_t): timezone =
  var local_time_tm = nTime_localtime timestamp
  let zone = local_time_tm.newZoneCStr()
  let nameo = PyUnicode_DecodeLocale(zone, "surrogateescape")
  zone.freeZoneCStr()

  let delta = local_time_tm.getUtcOffset timestamp
  result = newPyTimezone(delta, nameo)

let utc_timezone = timezone.utc()
# st = GET_CURRENT_STATE(current_mod); CONST_EPOCH(st)


proc local_timezone(utc_time: datetime): timezone =
  let epoch{.global.} = datetime(
            1970, 1, 1, 0, 0, 0, 0, utc_timezone, fold=0)
  let delta = utc_time - epoch
  let one_second = newTimedelta(0, 1, 0, false)
  let seconds = delta // one_second
  let timestamp = time_t(seconds)
  return local_timezone_from_timestamp(timestamp)

proc local_timezone_from_local(local_dt: datetime): timezone =

  template withFold(fold): untyped =
    local_to_seconds(
      local_dt.year, local_dt.month, local_dt.day,
      local_dt.hour, local_dt.minute, local_dt.second,
      fold)
  let fold = local_dt.fold
  var seconds = withFold fold
  template invalRaise(sec) =
    #if sec == -1: raise newException(OverflowError,
    #  "timestamp out of range for platform time_t")
    # Nim handles overflow and raises OverflowDefect
    discard
  invalRaise seconds
  let seconds2 = withFold int(bool(fold))
  invalRaise seconds2
  # Detect gap
  if seconds2 != seconds and (seconds2 > seconds) == bool(fold):
    seconds = seconds2
  
  let timestamp = seconds - epoch
  return local_timezone_from_timestamp(timestamp)

proc astimezone*(self: datetime; tz = TzNone): datetime =
  ## not the same as `DateTime.inZone(Timezone)`
  var
    tzinfo = tz
    self_tzinfo: tzinfo
  template setNaive =
    self_tzinfo = local_timezone_from_local(self)
  if self.tzinfo.isTzNone:
    setNaive()
  else:
    self_tzinfo = self.tzinfo

  # Conversion to self's own time zone is a NOP.
  if self_tzinfo == tzinfo:
    return self

  # Convert self to UTC.
  let offset = self_tzinfo.utcoffset(self)
  if offset.isTimeDeltaNone:
    setNaive()
  result = self - offset

  # Make sure result is aware and UTC.
  if result.tzinfo.isTzNone:
    result = newDatetime(result, tzinfo=timezone.utc)
  else:
    # Result is already aware - just replace tzinfo.
    result.tzinfo = utc_timezone
  
  # Attach new tzinfo and let fromutc() do the rest.
  if tzinfo.isTzNone:
    tzinfo = local_timezone(result)

  result.tzinfo = tzinfo
  result = tzinfo.fromutc(result)
