
import ../inner_decl
import ../../timedelta_impl/decl
import ../../timezone_impl/[
  decl, meth_by_datetime_getter]

func outOfDay(delta: timedelta): bool =
  # if use times.convert
  # JS backend does not reach `Microseconds` fineness.
  # NIM-BUG: `convert(Days, Microseconds, 1)`:
  # times.nim(417, 65)
  # Error: illegal conversion from '86400000000' to '[-2147483648..2147483647]'
  const OneDayMs = 1_000_000 * 3600 * 24
  abs(delta.inMicroseconds) > OneDayMs

template chkOneDay(delta: timedelta) =
  bind outOfDay
  if outOfDay delta:
    raise newException(ValueError, "offset must be a timedelta" &
                         " strictly between -timedelta(hours=24) and" &
                         " timedelta(hours=24).")

using self: datetime
func utcoffset*(self): timedelta =
  if self.tzinfo.isTzNone: return TimeDeltaNone
  result = self.tzinfo.utcoffset(self)
  result.chkOneDay()
func dst*(self): timedelta =
  if self.tzinfo.isTzNone: return TimeDeltaNone
  result = self.tzinfo.dst(self)
  result.chkOneDay()
func tzname*(self): string =
  ## .. hint:: this won't returns `None`, but may return a empty string
  self.tzinfo.tzname(self)
