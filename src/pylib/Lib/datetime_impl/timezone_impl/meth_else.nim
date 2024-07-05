

import ../pyerr
import ./decl
import ../timedelta_impl/[decl, meth]
import ../datetime_impl/[decl, meth]


using dt: datetime


using self: tzinfo

template chk_tzinfo(self) =
  if self.tzinfo != self:
    raise newException(ValueError, "fromutc: dt.tzinfo is not self")

template notNone(dt: timedelta) =
  if dt != TimeDeltaNone:
    raise newException(ValueError, "tzinfo.fromutc: timedelta is None")

method fromutc*(self; dt): datetime{.base.} =
  self.chk_tzinfo()
  let dtoff = dt.utcoffset()
  dtoff.notNone()

  var dtdst = dt.dst()
  dtdst.notNone()

  let delta = dtoff - dtdst

  result = dt + delta
  dtdst = result.dst() # dt.tzinfo.dst(result)
  dtdst.notNone()

  if bool(dtdst):
    result = result + dtdst


func timezone*(offset: timedelta): timezone = newPyTimezone(offset)

func timezone*(offset: timedelta; name: string): timezone =
  newPyTimezone(offset, name)


using self: timezone


method fromutc*(self; dt): datetime = 
  self.chk_tzinfo()
  dt + self.offset

func `==`*(self; o: timezone): bool = self.offset == o.offset
# `<`, `<=` raises NotImplementedError in CPython
