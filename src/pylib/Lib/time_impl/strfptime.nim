## this is the only module in time_impl that interact with ../../pylib
## 
## as strftime shall returns a `PyStr`
import std/times
import ./[
  types, converters, nstrpftime
]

#import ../../pystring/strimpl

func strftime*(format: string, st: struct_time): string =
  var dt: DateTime
  structTimeToDt st, dt
  strftime format, dt

func strftime*[S](format: S, st: struct_time): S =
  ## for `S` is `PyStr`
  S(strftime($format, st))

proc strptime*(s: string, f: string): struct_time =
  var dt: DateTime
  dt.strptime(s, f)
  dtToStructTime dt, result
