
import ../../../time_impl/[
  types, converters, nstrfptime
]

from std/strutils import multiReplace, replace, align, parseInt
import ../../timedelta_impl/decl
import ../../timezone_impl/[
  decl, meth_by_datetime_getter
]

include ./common
from std/times import DateTime, yearday, toParts

from ./importer import NotImplementedError

using self: datetime

# shall also has a `self: date`
func timetuple*(self): struct_time =
  var dstflag = -1
  if not self.tzinfo.isTzNone:
      let dst = self.tzinfo.dst(self)
      if not dst.isTimeDeltaNone:
        dstflag = int bool dst
  self.asNimDatetime.dtToStructTime result

using tzinfoarg: datetime

proc add_somezreplacement(s: var string, sep: string, tzinfo: tzinfo, tzinfoarg) =
  var offset: timedelta
  try:
    offset = tzinfo.utcoffset(tzinfoarg)
  except ValueError, NotImplementedError:
    return
  s.add format_utcoffset(offset.asDuration.toParts(), sep, prefix="")

const Py_NORMALIZE_CENTURY = true  # since CPython gh-120713
proc add_Zreplacement(s: var string, tzinfo: tzinfo, tzinfoarg) =
  try:
    s.add tzinfo.tzname(tzinfoarg)
  except NotImplementedError:
    return
  #[Since the tzname is getting stuffed into the
    format, we have to double any % signs so that
    strftime doesn't treat them as format codes.]#
  s = s.replace("%", "%%")

func wrap_strftime(self; format: string, tzinfoarg): string =
  #[Scan the input format, looking for %z/%Z/%f escapes, building
    a new format.  Since computing the replacements for those codes
    is expensive, don't unless they're actually used.]#

  let tzinfo = self.tzinfo
  var z_repl, Z_repl, z_col_repl: string
  if not tzinfo.isTzNone:
    z_repl.add_somezreplacement("", tzinfo, self)
    Z_repl.add_Zreplacement(tzinfo, self)
    z_col_repl.add_somezreplacement(":", tzinfo, self)

  let baseRepl = {
    "%z": z_repl,
    "%Z": Z_repl,
    "%:z": z_col_repl,
    "%f": align($self.microsecond, 6, '0')
  }
  when Py_NORMALIZE_CENTURY:
    let year = self.year
    template pad4(i: SomeInteger): string =
      align($i, 4, '0')
    let
      iG = parseInt(strftime("%G", self.asNimDatetime))
      iY = self.year
    let newfmt = format.multiReplace(
      @baseRepl & @{
        "%G": iG.pad4,
        "%Y": iY.pad4,
      }
    )
  else:
    let newfmt = format.multiReplace(baseRepl)

  strftime(newfmt, self.asNimDatetime)

func strftime*(self; format: string): string =
  wrap_strftime(self, format, self)

using _: typedesc[datetime]
func strptime*(_; datetime_string, format: string): datetime =
  var ndt: DateTime
  ndt.strptime(datetime_string, format)
  result = newDatetime(
    ndt,
  )

# TODO: easy: support all in nstrfptime.NotImplDirectives, with the help of calendar_utils

