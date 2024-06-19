
import std/times

proc time*(): float =
  epochTime() # getTime().toUnixFloat()

proc time_ns*(): int =
  let t = getTime()
  result = t.nanosecond
  result += typeof(result)(t.toUnix) * 1_000_000_000

when not defined(js):
  proc process_time*(): float =
    ## not available for JS backend, currently.
    cpuTime()
