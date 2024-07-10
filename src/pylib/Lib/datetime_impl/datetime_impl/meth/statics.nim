
include ./common
import ./init
import ./pytime, ./time_utils, ./to_seconds_utils, ./struct_tm_decl
export Timestamp
from ./calendar_utils import ord_to_ymd, iso_to_ymd, YMD
import ../../timezone_impl/[decl, meth_by_datetime]
import std/times

using _: typedesc[datetime]
func today*(_): datetime = newDatetime now()
func now*(_; tzinfo: tzinfo = TzNone): datetime =
  newDatetime(now(), tzinfo)


proc fromordinal*(_; ordinal: int): datetime =
  if ordinal < 1:
    raise newException(ValueError, "ordinal must be >= 1")
  var ymd: YMD
  ord_to_ymd(ordinal, ymd)
  init.datetime(ymd.year, ymd.month, ymd.day)

proc fromisocalendar*(_; year, week, day: int): datetime =
  var ymd: YMD
  iso_to_ymd((year, week, day), ymd)
  init.datetime(ymd.year, ymd.month, ymd.day)


# ## fromtimestamp
type
  N_TM_FUNC = proc (timer: time_t): Tm

proc datetime_from_timet_and_us(f: N_TM_FUNC, timet: time_t, us: int,
    tzinfo: tzinfo): datetime =
  let tm = f(timet)
  let timet = BiggestInt timet
  let
    year =  tm.tm_year + 1900
    month = tm.tm_mon + 1
    day =   tm.tm_mday
    hour =  tm.tm_hour
    minute= tm.tm_min
  #[The platform localtime/gmtime may insert leap seconds,
    indicated by tm.tm_sec > 59.  We don't care about them,
    except to the extent that passing them on to the datetime
    constructor would raise ValueError for a reason that
    made no sense to the user.]#
  let
    second = min(59, int tm.tm_sec)
  var fold = 0
  # local timezone requires to compute fold
  var shallCheckFold = tzinfo.isTzNone and f == nTime_localtime
    #[On Windows, passing a negative value to local results
      in an OSError because localtime_s on Windows does
      not support negative timestamps. Unfortunately this
      means that fold detection for time values between
      0 and max_fold_seconds will result in an identical
      error since we subtract max_fold_seconds to detect a
      fold. However, since we know there haven't been any
      folds in the interval [0, max_fold_seconds) in any
      timezone, we can hackily just forego fold detection
      for this time range. ]#
  when defined(windows):
    shallCheckFold = shallFold and timet - max_fold_seconds > 0
  if shallCheckFold:
    var
      result_seconds = utc_to_seconds(year, month, day, hour, minute, second)
    
    # Probe max_fold_seconds to detect a fold.
    var probe_seconds = local(epoch + timet - max_fold_seconds)
    var transition = result_seconds - probe_seconds - max_fold_seconds
    if transition < 0:
      probe_seconds = local(epoch + timet + transition)
      if probe_seconds == result_seconds:
        fold = 1
  
  return init.datetime(year, month, day, hour, minute,
                  second, us, tzinfo, fold)

proc datetime_from_timestamp(f: N_TM_FUNC, timestamp: Timestamp, tzinfo=TzNone): datetime =
  ##[Internal helper.
   Build datetime from a Python timestamp.  Pass localtime or gmtime for f,
   to control the interpretation of the timestamp.  Since a double doesn't
   have enough bits to cover a datetime's full range of precision, it's
   better to call datetime_from_timet_and_us provided you have a way
   to get that much precision (e.g., C time() isn't good enough).]##
  var
    timet: time_t
    us: long

  nPyTime_ObjectToTimeval(timestamp, timet, us, prHalfEven)
  return datetime_from_timet_and_us(f, timet, us.int, tzinfo)

proc fromtimestamp*(_; timestamp: Timestamp, tz=TzNone): datetime =
  result = datetime_from_timestamp(
    if tz.isTzNone: nTime_localtime else: nTime_gmtime,
    timestamp, tz)
  if not tz.isTzNone:
    result = tz.fromutc(result)
