
from ../delta_chk import chkOneDay
import ../timedelta_impl/[decl, meth]
import std/times
from std/strutils import toHex


type
  tzinfo* = ref object of RootObj  ## an abstract base class
  timezone* = ref object of tzinfo
    offset: timedelta
    name: string

const TzNone*: tzinfo = nil
func isTzNone*(self: tzinfo): bool = self == TzNone

func offset*(self: timezone): timedelta = self.offset  ## inner

func hash*(self: timezone): int = hash self.offset

{.pragma: benign, tags: [], raises: [], gcsafe.}
method toNimTimezone*(self: tzinfo): Timezone{.base, raises: [].} =
  #notImplErr(tzinfo.toNimTimezone)
  local()  # XXX: okey?

method toNimTimezone*(self: timezone): Timezone{.raises: [].} =
  let
    offset_dur = self.offset.asDuration
    offset_sec = offset_dur.inMicroseconds
    isDst = false
    # at least in Nim2.0, isDst doesn't affect the calculation of DateTime
  proc localZonedTimeFromTime(t: Time): ZonedTime{.benign.} =
    result.time = t
    result.utcOffset = typeof(result.utcOffset) offset_sec
    result.isDst = isDst
  proc localZonedTimeFromAdjTime(t: Time): ZonedTime{.benign.} =
    result.time = t - offset_dur
    result.utcOffset = typeof(result.utcOffset) offset_sec
    result.isDst = isDst
  newTimezone(self.name,
    localZonedTimeFromTime,
    localZonedTimeFromAdjTime
  )

let UTC* = timezone(offset: timedelta(0))
template utc*(_: typedesc[timezone]): timezone =
  ## timezone.utc
  bind UTC
  UTC

proc newPyTimezone*(offset: timedelta): timezone =
  if bool(offset) == false:
    return UTC
  offset.chkOneDay
  timezone(offset: offset)

func newPyTimezone*(offset: timedelta; name: string): timezone =
  offset.chkOneDay
  timezone(offset: offset, name: name)

type NimTimezoneProc = typeof(times.timezone)
static: assert NimTimezoneProc is proc
template utc*(_: NimTimezoneProc): timezone =
  ## if `import std/times`,
  ## timezone.utc may matches this.
  bind UTC
  UTC

func is_const_utc(tz: timezone): bool =
  bind `==`, utc_timezone  # `==` for ref, cmp on addr
  # utc_timezone is immutable, accessing it is fine
  {.noSideEffect.}:
    tz == UTC

func repr*(self: timezone): string =
  let type_name = $typeof(self)
  if self.is_const_utc:
    return type_name & ".utc"
  result = type_name & '(' & repr self.offset
  if self.name.len != 0:
    result.add ", "
    result.add self.name
  result.add ')'

func format_utcoffset(hours, minutes, seconds, microseconds: int,
    sep: char|string = ':', prefix="UTC"): string =
  var
    hours = hours
    minutes = minutes
    seconds = seconds
    microseconds = microseconds
  var sign = '+'
  if hours < 0 or minutes < 0 or seconds < 0 or microseconds < 0:
    template rev(i: var SomeInteger) =
      i = -i
    sign = '-'
    rev hours
    rev minutes
    rev seconds
    rev microseconds
  let sepLen = when sep is char: 1 else: sep.len
  result = newStringOfCap 7 + prefix.len + 3 * sepLen
  result.add prefix
  result.add sign
  template add(cs: char|string) = result.add cs
  template add0Nd(d: SomeInteger, n: int) =
    # we know `d` >= 0
    let sd = $d
    for _ in 1..(n-sd.len):
      result.add '0'
    result.add sd
  template add02d(d: SomeInteger) = add0Nd(d, 2)
  add02d hours
  add sep
  add02d minutes
  if seconds != 0:
    add sep
    add02d seconds
  if microseconds != 0:
    result.setLen result.len + 7
    add '.'
    add0Nd microseconds, 6

func format_utcoffset*(parts: DurationParts, sep: string|char = ':',
    prefix="UTC"): string =
  ## common code of CPython C-API `timezone_str` and `format_utcoffset`
  ## in `_datetimemodule.c
  when not defined(release):
    let days = parts[Days] + parts[Weeks] * 7
    assert days == 0, "timezone's init shall check its offset is within one day"
  let
    hours = parts[Hours]
    minutes = parts[Minutes]
    seconds = parts[Seconds]
    microseconds = parts[Microseconds]
  format_utcoffset(hours, minutes, seconds, microseconds,
    sep=sep, prefix=prefix)

template retIfNone(self) =
  if self.isTzNone: return "None"

func `$`*(self: timezone): string =
  ## timezone_str
  self.retIfNone
  if self.name.len != 0: return self.name
  if self.is_const_utc or
      bool(self.offset) == false:
    return "UTC"
  format_utcoffset(self.offset.asDuration.toParts(), sep=':', prefix="UTC")

method repr*(self: tzinfo): string{.base.} =
  ## object.__repr__
  self.retIfNone
  let hAddr = cast[int](self).toHex(sizeof(int)*2)
  "<datetime.tzinfo object at " & hAddr & '>'

method repr*(self: timezone): string =
  ## timezone_repr
  self.retIfNone
  result = $typeof(self)
  if self.is_const_utc:
    result.add ".utc"
    return
  result.add '('
  result.add meth.repr(self.offset)
  if self.name.len != 0:
    result.add ", "
    result.add self.name
  result.add ')'
