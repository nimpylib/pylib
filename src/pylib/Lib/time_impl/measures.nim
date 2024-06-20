
import std/times

proc time*(): float =
  epochTime() # getTime().toUnixFloat()

const ns_per_s = 1_000_000_000
proc time_ns*(): int64 =
  let t = getTime()
  type R = typeof(result)
  result = R t.nanosecond
  result += R(t.toUnix) * ns_per_s

when not defined(js):
  proc process_time*(): float =
    ## not available for JS backend, currently.
    cpuTime()
