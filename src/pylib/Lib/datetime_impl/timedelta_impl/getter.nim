

import ./decl
import std/times

using parts: DurationParts
using self: timedelta


func daysImpl*(parts): int64 =
  result = parts[Weeks] * 7 + parts[Days]
  if result <= 0:
    if parts[Hours] < 0 or parts[Minutes] < 0 or parts[Seconds] < 0 or parts[Microseconds] < 0:
      result.dec

func days*(self): int64 = self.asDuration.toParts.daysImpl()

func secondsImpl*(parts): int64 =
  ## result is never negative. In Python, only timedelta.days may be negative
  # do not use `.inSeconds()`, as that's a sum
  result = parts[Seconds]
  result.inc convert(Hours, Seconds, parts[Hours])
  result.inc convert(Minutes, Seconds, parts[Minutes])
  if result <= 0:
    result.inc convert(Days, Seconds, 1)
  if parts[Microseconds] < 0:
    result.dec

func seconds*(self): int64 = self.asDuration.toParts.secondsImpl()

func microsecondsImpl*(parts): int64 =
  ## result is never negative. In Python, only timedelta.days may be negative
  # do not use .inMicroseconds
  # nanoseconds part is always 0 for timedelta's Duration attr
  result = parts[Microseconds]
  result.inc convert(Milliseconds, Microseconds, parts[Milliseconds])
  if result <= 0:
    result.inc 1_000_000

func microseconds*(self): int64 = self.asDuration.toParts.microsecondsImpl()
