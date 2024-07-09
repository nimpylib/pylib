

import ./decl
import ../timedelta_impl/decl as td_decl
import ../datetime_impl/decl as dt_decl


using dt: datetime


using self: tzinfo

func timezone*(offset: timedelta): timezone = newPyTimezone(offset)

func timezone*(offset: timedelta; name: string): timezone =
  newPyTimezone(offset, name)


using self: timezone

func `==`*(self; o: timezone): bool = self.offset == o.offset
# `<`, `<=` raises NotImplementedError in CPython
