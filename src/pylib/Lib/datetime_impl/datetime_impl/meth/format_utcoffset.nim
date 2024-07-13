
include ./common
from std/times import toParts
import ../../timedelta_impl/decl
import ../../timezone_impl/[
  decl as timezone_decl, meth_by_datetime_getter
]
from ./importer import NotImplementedError

func add_format_utcoffset*(s: var string, sep: string, tzinfo: tzinfo, tzinfoarg: datetime) =
  ## `tzinfo` must not be nil
  var offset: timedelta
  try:
    offset = tzinfo.utcoffset(tzinfoarg)
  except ValueError, NotImplementedError:
    return
  s.add format_utcoffset(offset.asDuration.toParts(), sep, prefix="")
