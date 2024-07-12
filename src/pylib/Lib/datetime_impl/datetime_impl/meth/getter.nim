## See also: ./getter_requires_op ./getter_of_date

import ../inner_decl
import ../../timedelta_impl/decl
import ../../timezone_impl/[
  decl, meth_by_datetime_getter]
from ../../delta_chk import chkOneDay

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
