## .. include:: ./doc/nstrfptime.rst
import std/times
import ./[
  types, converters, nstrpftime
]

func strftime*(format: string, st: struct_time): string =
  var dt: DateTime
  structTimeToDt st, dt
  strftime format, dt

func strftime*[S](format: S, st: struct_time): S =
  ## EXT.
  S(strftime($format, st))

func strftime*(format: string, st: Some_struct_time_tuple): string =
  strftime format, struct_time st

proc strptime*(s: string, f: string): struct_time =
  ## .. include:: ./doc/nstrptimeDiff.rst
  var dt: DateTime
  dt.strptime(s, f)
  dtToStructTime dt, result
