

import ../pyerr
import ./decl
import ../timedelta_impl/decl
import ../datetime_impl/[decl, meth]


using dt: datetime


using self: tzinfo

func timezone*(offset: timedelta): timezone = newPyTimezone(offset)

func timezone*(offset: timedelta; name: string): timezone =
  newPyTimezone(offset, name)


using self: timezone

func `==`*(self; o: timezone): bool = self.offset == o.offset
# `<`, `<=` raises NotImplementedError in CPython
