

# status: not tested yet; not finished

import std/os as nos
proc sleep*(s: int) =
  nos.sleep 1000 * s

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
  struct_time* = tuple[
    tm_year: int,
    tm_mon: range[1 .. 12],
    tm_mday: MonthdayRange,
    tm_hour: HourRange,
    tm_min: MinuteRange,
    tm_sec: range[0 .. 61],  # SecondRange is range[0 .. 60]
    tm_wday: range[0 .. 6],
    tm_yday: range[0 .. 366]  # YeardayRange is range[0 .. 365]
  ]

func dtToStructTime(dt: DateTime, res: var struct_time) =
  res = (
    dt.year,
    dt.month.int,
    dt.monthday,
    dt.hour,
    dt.minute,
    dt.second,
    dt.weekday.int,
    dt.yearday
  )

func structTimeToDt(st: struct_time, res: var DateTime) =
  let mon = st.tm_mon.Month
  {.noSideEffect.}:
    res = dateTime(
      st.tm_year,
      mon,
      st.tm_mday,
      st.tm_hour,
      st.tm_min,
      st.tm_sec,
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


proc gmtime*(): struct_time = dtToStructTime(now(), result)
proc localtime*(): struct_time = dtToStructTime(now().inZone(utc()), result)

func mktime*(t: struct_time): float =
  var dt: DateTime
  structTimeToDt(t, dt)
  dt.toTime().toUnixFloat()


