## meth required by datetime class

import ../timedelta_impl/decl
import ../datetime_impl/inner_decl
import ./decl
import ../pyerr

using dt: datetime
method utcoffset*(self: tzinfo; dt): timedelta{.base.} = notImplErr(tzinfo.utcoffset)
method utcoffset*(self: timezone; _: datetime): timedelta = self.offset

method dst*(self: tzinfo; dt): timedelta{.base.} = notImplErr(tzinfo.dst)
method dst*(self: timezone; _: datetime): timedelta =
  ## returns nil
  nil

method tzname*(self: tzinfo; dt: datetime): string{.base.} = notImplErr(tzinfo.tzname)
method tzname*(self: timezone; _: datetime): string = $self
