
import std/times
import ../timezone_impl/decl

type
  datetime* = ref object
    dt: Datetime
    tzinfo*: tzinfo

func newDatetime*(dt: Datetime, tzinfo: tzinfo = nil): datetime =
  datetime(dt: dt, tzinfo: tzinfo)

func asNimDatetime*(self: datetime): DateTime = self.dt

using self: datetime
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
