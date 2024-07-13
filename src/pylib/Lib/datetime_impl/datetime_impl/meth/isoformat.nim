
include ./common
import ./format_utcoffset
import ../../timezone_impl/decl as timezone_decl
from std/times import format
from std/strutils import parseEnum

type
  IsoFormatTimespec*{.pure.} = enum
    auto
    hours
    minutes
    seconds
    milliseconds
    microseconds

using self: datetime # | date
func isoformat*(self; sep: char|string, timespec: IsoFormatTimespec): string =
  result = newStringOfCap 28  # 20 + 5 + 3  # the max possible cap  # sep is a UTF-8 char, at most 3-bytes
  template add(cs: char|string) = result.add cs
  template addDtF(s) =
    result.add self.asNimDatetime.format s
  addDtf "yyyy-MM-dd"
  add sep
  addDtf "HH"
  template add0Nd(d: SomeInteger, n: int) =
    let sd = $d
    for _ in 1..(n-sd.len):
      result.add '0'
    result.add sd
  let us = self.microsecond
  let ntspec =
    if timespec == IsoFormatTimespec.auto:
      if us == 0: seconds
      else: microseconds
    else:
      timespec
  case ntspec
  of IsoFormatTimespec.auto, hours: discard
  of minutes:
    addDtF ":mm"
  of seconds:
    addDtF ":mm:ss"
  of milliseconds:
    addDtF ":mm:ss'.'fff"
  of microseconds:
    addDtF ":mm:ss'.'ffffff"
  
  # We need to append the UTC offset.
  if self.tzinfo.isTzNone:
    return
  result.add_format_utcoffset(sep=":", self.tzinfo, self)

func isoformat*(self; sep: char|string = "T", timespec="auto"): string =
  let ts = parseEnum[IsoFormatTimespec](timespec)
  self.isoformat(sep, ts)

func `$`*(self): string =
  ## datetime_str
  self.isoformat(' ', IsoFormatTimespec.auto)

func repr*(self): string =
  ## datetime_repr
  result = $typeof(self)
  result.add '('
  template addA(attr) = result.add $self.attr
  template addP = result.add ", "
  template addAP(attr) =  addA(attr); addP()
  addAP year
  addAP month
  addAP day
  addAP hour
  if self.microsecond != 0:
    addAP minute
    addAP second
    addA microsecond
  elif self.second != 0:
    addAP minute
    addA second
  else:
    addA minute
  if self.fold != 0:
    addP()
    result.add "fold="
    addA fold
  if not self.tzinfo.isTzNone:
    addP()
    result.add "tzinfo="
    result.add timezone_decl.repr(self.tzinfo)
  result.add ')'
