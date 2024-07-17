

import ./timedelta_impl/decl

func outOfDay(delta: timedelta): bool =
  # if use times.convert
  # JS backend does not reach `Microseconds` fineness.
  # NIM-BUG: `convert(Days, Microseconds, 1)`:
  # times.nim(417, 65)
  # Error: illegal conversion from '86400000000' to '[-2147483648..2147483647]'
  const OneDayMs = int64(1_000_000) * 3600 * 24
  abs(delta.inMicroseconds) > OneDayMs

template chkOneDay*(delta: timedelta) =
  bind outOfDay
  if outOfDay delta:
    raise newException(ValueError, "offset must be a timedelta" &
                         " strictly between -timedelta(hours=24) and" &
                         " timedelta(hours=24). not " & repr(delta))
