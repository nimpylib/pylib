
import std/times
import ../timezone_impl/decl

type
  datetime* = ref object
    dt: Datetime
    tzinfo*: tzinfo

func newDatetime*(dt: Datetime, tzinfo: tzinfo = nil): datetime =
  datetime(dt: dt, tzinfo: tzinfo)

func asNimDatetime*(self: datetime): DateTime = self.dt

