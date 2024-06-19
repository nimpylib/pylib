## funcs about struct_time
## 
## its initializer, and a inverse function `mktime`

import std/times
import ./[types, converters]

proc gmtime*(): struct_time = dtToStructTime(now().inZone(utc()), result)
proc localtime*(): struct_time = dtToStructTime(now(), result)

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


func mktime*(t: struct_time): float =
  var dt: DateTime
  structTimeToDt(t, dt)
  dt.toTime().toUnixFloat()

wrapTuple mktime, struct_time_tuple
