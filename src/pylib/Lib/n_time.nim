##[
# time for Nim

the only difference with Python's is where some types in time is `str`,
there is `string` in `n_time`'s.

e.g. `n_time.ctime()` returns a string

## py diff

Currently,
`tm_name` is either "LOCAL" or "Etc/UTC", due to std/times only returning those two.


]##

#[
## impl note
Some note about implement details the different between std/times and Python's times

std/times DateTime's utcOffset is opposed to struct_time.tm_gmtoff
e.g.  in the east, DateTime.utcOffset is negative.
]#

import std/times
import ./time_impl/[
  types, converters, strfptime, asctimeImpl,
  struct_time_funcs,
  sleep_impl, measures
]
fetchDoc(docTable)
export fetchDoc, docTable

export sleep, measures
export types except isUtcZone, initStructTime
export toTuple
export struct_time_funcs

export strfptime


const DefaultTimeFormat* = "%a %b %d %H:%M:%S %Y"

proc asctime*(): string = asctime now()
func asctime*(t: struct_time): string = 
  # do not use:
  # strftime DefaultTimeFormat, t
  # as %d is not space-padding, but '0'-padding
  var dt: DateTime
  structTimeToDt t, dt
  asctime dt

wrapTuple asctime

proc ctime*(): string = asctime now()

proc ctime*(secs: float|int64): string =
  asctime localtime secs

proc strftime*(format: string): string{.fetchDoc(docTable).} =
  strftime(format, localtime())

proc strptime*(s: string): struct_time{.fetchDoc(docTable).} =
  strptime(s, DefaultTimeFormat)


