
import ../timedelta_impl/[decl, meth]
import std/times
import std/hashes


type
  tzinfo* = ref object of RootObj  ## an abstract base class
  timezone* = ref object of tzinfo
    offset: timedelta
    name: string

const TzNone*: tzinfo = nil
func isTzNone*(self: tzinfo): bool = self == TzNone

func offset*(self: timezone): timedelta = self.offset  ## inner

func hash*(self: timezone): int = hash self.offset

func newPyTimezone*(offset: timedelta): timezone =
  timezone(offset: offset)
func newPyTimezone*(offset: timedelta; name: string): timezone =
  timezone(offset: offset, name: name)


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

let utc_timezone = newPyTimezone(timedelta(0))
template utc*(_: typedesc[timezone]): timezone =
  ## timezone.utc
  bind utc_timezone
  utc_timezone

type NimTimezoneProc = typeof(times.timezone)
static: assert NimTimezoneProc is proc
template utc*(_: NimTimezoneProc): timezone =
  ## if `import std/times`,
  ## timezone.utc may matches this.
  bind utc_timezone
  utc_timezone

func is_const_utc(tz: timezone): bool =
  bind `==`, utc_timezone  # `==` for ref, cmp on addr
  # utc_timezone is immutable, accessing it is fine
  {.noSideEffect.}:
    tz == utc_timezone

func repr*(self: timezone): string =
  let type_name = $typeof(self)
  if self.is_const_utc:
    return type_name & ".utc"
  result = type_name & '(' & repr self.offset
  if self.name.len != 0:
    result.add ", "
    result.add self.name
  result.add ')'

func divmod[I](x: I, y: Natural, r: var I): I =
  ## returns floorDiv(x, y)
  result = x div y
  r = x - result * y
  if r < 0:
    result.dec
    r.inc y
  assert 0 <= r and r < y

func `$`*(self: timezone): string =
  if self.name.len != 0: return self.name
  let parts = self.offset.asDuration.toParts()
  let
    days = parts[Days]
    secs = parts[Seconds]
    us = parts[Microseconds]
  if self.is_const_utc or
      days == 0 and secs == 0 and us == 0:
    return "UTC"
  var
    sign: char
    offset: timedelta
  if days < 0:
    sign = '-'
    offset = -self.offset
  else:
    sign = '+'
    offset = self.offset  # new ref
  let
    nparts = offset.asDuration.toParts()
    microseconds = nparts[Microseconds]
  var seconds = nparts[Seconds]
  var minutes = divmod(seconds, 60, seconds)
  let hours = divmod(minutes, 60, minutes)
  result = newStringOfCap 12
  result.add "UTC"
  template add(c: char) = result.add c
  add sign
  template add0Nd(d: SomeInteger, n: int) =
    # we know d >= 0
    let sd = $d
    for _ in 1..(n-sd.len):
      result.add '0'
    result.add sd
  template add02d(d: SomeInteger) = add0Nd(d, 2)
  add02d hours
  add ':'
  add02d minutes
  if seconds != 0:
    add ':'
    add02d seconds
  if microseconds != 0:
    result.setLen 19
    add '.'
    add0Nd microseconds, 6
