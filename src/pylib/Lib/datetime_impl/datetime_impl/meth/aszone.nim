
include ./common

import ../../timedelta_impl/[decl, meth]
import ../../timezone_impl/[decl, meth_by_datetime_getter, meth_by_datetime]

import ./time_utils, ./zonename_utils, ./to_seconds_utils
from ./state_consts import CONST_EPOCH, utc_timezone
import ./op

when not HAVE_STRUCT_TM_TM_ZONE: 
  import ./init
  import ./struct_tm_helper  # cTmToNormCall
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
  let nameo = local_time_tm.zonename

  let delta = local_time_tm.getUtcOffset timestamp
  result = newPyTimezone(delta, nameo)

proc local_timezone(utc_time: datetime): timezone =
  let delta = utc_time - CONST_EPOCH
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
  
  let
    diff = seconds - epoch
    timestamp = time_t(diff)
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
