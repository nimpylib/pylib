
import ./n_datetime

export n_datetime except tzname, isoformat, strftime, ctime

import ../pystring/strimpl
import ../noneType
import ../pyerrors/simperr


method tzname*(tz: tzinfo; dt: datetime): PyStr{.base.} =
  str n_datetime.tzname(tz, dt)
method tzname*(tz: timezone; dt: datetime): PyStr =
  str n_datetime.tzname(tz, dt)
func tzname*(dt: datetime): PyStr =
  ## .. hint:: this won't returns `None`, but may return a empty string
  str n_datetime.tzname(dt)

using self: datetime # | date
func strftime*(self; format: PyStr): PyStr = str n_datetime.strftime(self, $format)
func isoformat*(self; sep: StringLike = 'T', timespec="auto"): PyStr =
  template lenErr =
    raise newException(TypeError, "isoformat() argument 1 must be a unicode character, not str")
  when sep is string:
    let sep = str sep    
  if sep.len != 1: lenErr()
  when sep is char:
    let ch = sep
  else:
    let ch = $sep
  str n_datetime.isoformat(self, sep=ch, timespec=timespec)
func str*(self): PyStr = self.isoformat(' ')
func str*(self: timedelta): PyStr = $self
func ctime*(self): PyStr = str n_datetime.ctime(self)

func `==`*(tzinfo: tzinfo, n: NoneType): bool = tzinfo.isTzNone
func `==`*(delta: timedelta, n: NoneType): bool = delta.isTimeDeltaNone

converter noneToTzInfo*(_: NoneType): tzinfo = TzNone
