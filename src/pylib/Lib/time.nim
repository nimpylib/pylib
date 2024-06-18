

##[

## py diff

Currently,
`tm_name` is either "LOCAL" or "Etc/UTC", due to std/times only returning those two.

## Some note about implement details the different between std/times and Python's times

------

std/times DateTime's utcOffset is opposed to struct_time.tm_gmtoff
e.g.  in the east, DateTime.utcOffset is negative.

]##

# status: not tested yet; not completed

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


#when defined(posix): import std/posix

import std/times

proc time*(): float =
  epochTime() # getTime().toUnixFloat()

proc time_ns*(): int =
  let t = getTime()
  result = t.nanosecond
  result += t.toUnix * 1_000_000_000

proc process_time*(): float = cpuTime()

type
  struct_time_tuple* = tuple
    tm_year: int
    tm_mon: range[1 .. 12]
    tm_mday: MonthdayRange
    tm_hour: HourRange
    tm_min: MinuteRange
    tm_sec: range[0 .. 61]  # SecondRange is range[0 .. 60]
    tm_wday: range[0 .. 6]
    tm_yday: range[0 .. 366]  # YeardayRange is range[0 .. 365]
    tm_isdst: int
  
  struct_time* = ref object
    tm_year*: int
    tm_mon*: range[1 .. 12]
    tm_mday*: MonthdayRange
    tm_hour*: HourRange
    tm_min*: MinuteRange
    tm_sec*: range[0 .. 61]  # SecondRange is range[0 .. 60]
    tm_wday*: range[0 .. 6]
    tm_yday*: range[0 .. 366]  # YeardayRange is range[0 .. 365]
    tm_isdst*: int
    tm_zone*: string  ## .. warning:: curently is only "LOCAL" or "Etc/UTC"
    tm_gmtoff*: int

template isUtcZone(st: struct_time): bool =
  ## zone is only local or utc
  st.tm_gmtoff == 0

converter toTuple*(st: struct_time): struct_time_tuple =
  ## XXX: `tuple` is Nim's keyword, so no symbol can be named `tuple`
  (
    st.tm_year,
    st.tm_mon,
    st.tm_mday,
    st.tm_hour,
    st.tm_min,
    st.tm_sec,
    st.tm_wday,
    st.tm_yday,
    st.tm_isdst,
  )

template initStructTime(
    year,
    mon,
    mday,
    hour,
    min,
    sec,
    wday,
    yday,
    isdst,
    zone,
    gmtoff
  ): struct_time = struct_time(
    tm_year:  year,
    tm_mon:   mon,
    tm_mday:  mday,
    tm_hour:  hour,
    tm_min:   min,
    tm_sec:   sec,
    tm_wday:  wday,
    tm_yday:  yday,
    tm_isdst: isdst,
    tm_zone:  zone,
    tm_gmtoff:gmtoff
  )

func dtToStructTime(dt: DateTime, res: var struct_time) =
  res = initStructTime(
    dt.year,
    dt.month.int,
    dt.monthday,
    dt.hour,
    dt.minute,
    dt.second,
    dt.weekday.int,
    dt.yearday,
    dt.isDst.int,
    dt.timezone.name,
    -dt.utcOffset
  )

func structTimeToDt(st: struct_time, res: var DateTime) =
  # XXX: TODO: consider tzone
  let mon = st.tm_mon.Month
  {.noSideEffect.}:
    res = dateTime(
      st.tm_year,
      mon,
      st.tm_mday,
      st.tm_hour,
      st.tm_min,
      st.tm_sec,
      zone=(if st.isUtcZone: utc() else: local())
    )
  assert st.tm_wday == res.weekday.int

proc gmtime*(secs: int64): struct_time =
  let t = fromUnix secs
  let dt = t.utc()
  dtToStructTime(dt, result)

proc localtime*(secs: int64): struct_time =
  let t = fromUnix secs
  let dt = t.local()
  dtToStructTime(dt, result)

proc gmtime*(secs: float): struct_time =
  let t = fromUnixFloat secs
  let dt = t.utc()
  dtToStructTime(dt, result)

proc localtime*(secs: float): struct_time =
  let t = fromUnixFloat secs
  let dt = t.local()
  dtToStructTime(dt, result)

proc gmtime*(): struct_time = dtToStructTime(now().inZone(utc()), result)
proc localtime*(): struct_time = dtToStructTime(now(), result)

func mktime*(t: struct_time): float =
  var dt: DateTime
  structTimeToDt(t, dt)
  dt.toTime().toUnixFloat()

#func strftime*()
