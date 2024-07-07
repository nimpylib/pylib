
import std/times
import ../timezone_impl/decl

type
  datetime* = ref object
    dt: Datetime
    tzinfo*: tzinfo
    isfold: bool
    hashcode: int
  PyDatetime* = datetime

template dtNormTz*(tz: tzinfo): Timezone =
  if tz.isTzNone: local() else: tz.toNimTimezone

func newDatetime*(dt: Datetime, tzinfo: tzinfo = nil, isfold = false): datetime =
  datetime(dt: dt, tzinfo: tzinfo, isfold: isfold)

func asNimDatetime*(self: datetime): DateTime = self.dt

using self: datetime
func isfold*(self): bool = self.isfold
template wrap(dtA, DtA){.dirty.} =
  func dtA*(self): int = self.dt.DtA
template wrap(dtA) = wrap(dtA, dtA)

template wrap(dtA, DtA, cvt){.dirty.} =
  func dtA*(self): int = self.dt.DtA.cvt

wrap year
wrap month, month, ord
wrap day, monthday
wrap hour
wrap minute
wrap second
template ns2us(ns): untyped = ns div 1000
wrap microsecond, nanosecond, ns2us
func fold*(self): int = int self.isfold

proc newDatetime*(self: datetime,
    tzinfo: tzinfo = self.tzinfo, isfold = self.isfold): datetime =
  newDatetime(
    dateTime(
      self.dt.year,
      self.dt.month, self.dt.monthday,
      self.dt.hour, self.dt.minute, self.dt.second,
      self.microsecond,
      zone = dtNormTz tzinfo
    ), tzinfo, isfold
  )

func hashcode*(self): int = self.hashcode
func `hashcode=`*(self; h: int) = self.hashcode = h
