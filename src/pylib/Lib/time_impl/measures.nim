## .. hint::
##  all functions are pretended as `noSideEffect` pramga,
##  as I myself doesn't think noSideEffect means pure function,
##  but pure function is must noSideEffect, the opposite is not true.
##  However, Nim manual seems to mixin them.
## 

import std/times
import std/monotimes

func time*(): float =
  {.noSideEffect.}:
    epochTime() # getTime().toUnixFloat()

const ns_per_s = 1_000_000_000
func time_ns*(): int64 =
  {.noSideEffect.}:
    let t = getTime()
  type R = typeof(result)
  result = R t.nanosecond
  result += R(t.toUnix) * ns_per_s

when not defined(js):
  func process_time*(): float =
    ## not available for JS backend, currently.
    {.noSideEffect.}:
      cpuTime()

func monotonic_ns*(): int64 =
  template impl: untyped = getMonoTime().ticks()
  when defined(windows): impl
  else:
    {.noSideEffect.}:
      result = impl

func monotonic*(): float =
  when defined(js):
    monotonic_ns().float / ns_per_s
    # see Nim#23746
    # JS only: without `.float`, compile fail
    # JS failed to compile `int64/int64`
  else:
    monotonic_ns().float / ns_per_s

func perf_counter*(): float = monotonic()
func perf_counter_ns*(): int64 = monotonic_ns()

