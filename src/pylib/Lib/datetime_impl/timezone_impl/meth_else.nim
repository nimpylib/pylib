

import ./decl
import ../timedelta_impl/decl as td_decl

using self: tzinfo

proc timezone*(offset: timedelta): timezone = newPyTimezone(offset)

func timezone*(offset: timedelta; name: string): timezone =
  newPyTimezone(offset, name)


using self: timezone

func `==`*(self; o: timezone): bool = self.offset == o.offset
# `<`, `<=` raises NotImplementedError in CPython
