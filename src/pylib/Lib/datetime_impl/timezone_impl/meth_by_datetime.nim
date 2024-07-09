## meth required by datetime class

import ../timedelta_impl/[decl, meth]
import ../datetime_impl/inner_decl
import ../datetime_impl/meth/[getter, op]
import ./decl
import ../pyerr

using dt: datetime


template chk_tzinfo(self: tzinfo; dt) =
  if dt.tzinfo != self:
    raise newException(ValueError, "fromutc: dt.tzinfo is not self")

template notNone(td: timedelta) =
  if td.isTimeDeltaNone:
    raise newException(ValueError, "tzinfo.fromutc: timedelta is None")

method fromutc*(self: tzinfo; dt): datetime{.base.} =
  self.chk_tzinfo(dt)
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

method fromutc*(self: timezone; dt): datetime = 
  self.chk_tzinfo(dt)
  dt + self.offset
