
import std/times
import std/hashes
import ../timezone_impl/[decl, meth_by_datetime]
import ../timedelta_impl/[decl, meth]  # import `-`, init for hash
import ./calendar_utils
import ./inner_decl
export inner_decl except hashcode, `hashcode=`
#[
  we split decl into inner_decl, decl
  as if not, there will be cyclic deps between datetime_impl and timezone_impl

  And we did not merge this to ./meth.nim as we control export:
  ``export inner_decl except hashcode, `hashcode=` ``
]#

func outOfDay(delta: timedelta): bool =
  when defined(js):
    # JS backend does not reach `Microseconds` fineness.
    # NIM-BUG: `convert(Days, Microseconds, 1)`:
    # times.nim(417, 65)
    # Error: illegal conversion from '86400000000' to '[-2147483648..2147483647]'
    const OneDayUs = convert(Days, Milliseconds, 1)
    abs(delta.inMicroseconds) div 1000 > OneDayUs
  else:
    const OneDayMs = convert(Days, Microseconds, 1)
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

proc hashImpl(self): int =
  let self0 =
    if self.isfold:
      newDatetime(self, isfold=false)
    else: self
  let offset = self0.utcoffset()
  if offset.isTimeDeltaNone:
    result = hash [
          self.year,
          self.month, self.day,
          self.hour, self.minute, self.second, self.microsecond,
    ]
  else:
    let days = ymd_to_ord(
      self.year, self.month, self.day)
    let seconds = self.hour * 3600 +
                  self.minute * 60 + self.second
    let temp1 = newTimedelta(days=days, seconds=seconds,
                  microseconds=self.microsecond, true)
    let temp2 = temp1 - offset
    result = hash temp2

proc hash*(self): int =
  if self.hashcode == -1:
    self.hashcode = self.hashImpl()
  result = self.hashcode
