import std/times
import ./types, ./converters, ./nstrfptime

fetchDoc(docTable)
export fetchDoc, docTable

func strftime*(format: string, st: struct_time): string{.fetchDoc(docTable).} =
  var dt: DateTime
  structTimeToDt st, dt
  strftime format, dt

func strftime*[S](format: S, st: struct_time): S =
  ## EXT.
  S(strftime($format, st))

func strftime*(format: string, st: Some_struct_time_tuple): string
    {.fetchDoc(docTable).} =
  strftime format, struct_time st

proc strptime*(s: string, f: string): struct_time{.fetchDoc(docTable).} =
  var dt: DateTime
  dt.strptime(s, f)
  dtToStructTime dt, result
