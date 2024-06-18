

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


import std/times
import ./time_impl/[
  types, converters, sleep_impl, strfptime
]
export sleep
export types except isUtcZone
export toTuple
export strfptime

proc time*(): float =
  epochTime() # getTime().toUnixFloat()

proc time_ns*(): int =
  let t = getTime()
  result = t.nanosecond
  result += typeof(result)(t.toUnix) * 1_000_000_000

when not defined(js):
  proc process_time*(): float = cpuTime()

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
