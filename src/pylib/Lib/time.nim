##[ time

See `n_time modeule<n_time.html>` for details about implementation
]##

import ./n_time
import ../pystring/strimpl

export sleep, measures
export types except isUtcZone, initStructTime
export toTuple
export struct_time_funcs

const DefaultTimeFormat* = str DefaultTimeFormat

proc asctime*(): PyStr = str n_time.asctime()

template wrap1(f, arg): PyStr =
  str n_time.f(arg)

func asctime*(t: Some_struct_time): PyStr =
  wrap1 asctime, t

proc ctime*(): PyStr = str ctime()
proc ctime*(secs: float|int64): PyStr =
  wrap1 ctime, secs

func strftime*(format: PyStr, st: Some_struct_time): PyStr =
  str n_time.strftime($format, st)

proc strftime*(format: PyStr): PyStr =
  strftime format, localtime()

proc strptime*(s: PyStr; format = DefaultTimeFormat): struct_time =
  n_time.strptime($s, $format)

