
import std/macros
import std/times
import ./decl
import ./calendar_utils
from ../obj_utils import `@=`
import ../timedelta_impl/[
  decl, meth]
import ../timezone_impl/[
  decl, meth_by_datetime
]
import ../pyerr

macro getRangeStr(typ: typedesc): string =
  let tNode = typ.getType[1]
  let t =
    if tNode.typeKind == ntyEnum: tNode.getTypeInst
    # if use others other than getTypeInst for enum,
    # `ord` will always start with 0 (even for enum whose first item is 1-ord)
    else: tNode.getTypeImpl
  result = quote do:
    $`t`.low.ord & ".." & $`t`.high.ord

template raiseValueError(msg) =
    raise newException(ValueError, msg)

template chkSto(x: typed, aliasX: untyped; typ: typedesc) =
  var aliasX: typ
  try:
    aliasX = typ(x)
  except RangeDefect:
    raiseValueError(astToStr(x) & " must be in " & typ.getRangeStr)

func ltoUpper(c: char): char = chr(c.ord + 'A'.ord - 'a'.ord)
func ltoCap(s: string): string = s[0].ltoUpper & s.substr(1)

macro catRange(x): untyped =
  ident(x.strVal.ltoCap & "Range")

template chkSto(x: typed, aliasX: untyped) = chkSto(x, aliasX, catRange(x))

func checkFold(fold: int): bool{.raises: [ValueError].} =
  if fold == 1: result = true
  elif fold == 0: result = false
  else:
    raiseValueError("fold must be either 0 or 1")

{.push warning[ProveInit]: off.}
# for MonthdayRange:
# when `except RangeDefect`, a exception is raised, so the routinue just stops 
# so this is safe.
proc datetime*(year, month, day: int,
  hour=0, minute=0, second=0, microsecond=0,
  tzinfo: tzinfo = nil, fold=0
): datetime{.raises: [ValueError].} =
  runnableExamples:
    let dt = datetime(1900, 2, 28)
    echo repr dt
  chkSto month, mon, Month

  #chkSto day, d, MonthdayRange
  if day < 1 or day > getDaysInMonth(mon, year):
    raiseValueError "day is out of range for month"
  let d = MonthdayRange(day)

  chkSto hour, h
  chkSto minute, min
  chkSto second, s
  let nanosecond = microsecond * 1000
  chkSto nanosecond, ns

  result = newDatetime(times.dateTime(
    year, mon, d, h, min, s, ns, 
      zone = dtNormTz tzinfo
  ), tzinfo, fold.checkFold)

{.pop.}



func max*(_: typedesc[datetime]): datetime = datetime(9999, 12, 31, 23, 59, 59, 999999)
func min*(_: typedesc[datetime]): datetime = datetime.datetime(1, 1, 1, 0, 0)
func resolution*(_: typedesc[datetime]): timedelta = timedelta.resolution

func today*(_: typedesc[datetime]): datetime = newDatetime now()
func now*(_: typedesc[datetime], tzinfo: tzinfo = TzNone): datetime =
  newDatetime(now(), tzinfo)

using self: datetime
proc `+`*(self; delta: timedelta): datetime =
  newDatetime(self.asNimDatetime + delta.asDuration, self.tzinfo)

proc `-`*(self; delta: timedelta): datetime =
  newDatetime(self.asNimDatetime - delta.asDuration, self.tzinfo)

template ymd_to_ord(self: datetime): int =
  ymd_to_ord(
    self.year, self.month, self.day)

proc `-`*(self; dt: datetime): timedelta =
  var
    offset1, offset2: timedelta
    
  if self.tzinfo @= dt.tzinfo:
    offset1 = TimeDeltaNone
    offset2 = TimeDeltaNone
  else:
    offset1 = self.utcoffset
    offset2 = dt.utcoffset
    if (
      not(offset1.isTimeDeltaNone) != not(offset2.isTimeDeltaNone)
    ):
      raise newException(TypeError, "can't subtract offset-naive and " &
                                    "offset-aware datetimes")
  var offdiff: timedelta = TimeDeltaNone
  if not (offset1 @= offset2) and offset1 != offset2:
    offdiff = offset1 - offset2
  let delta_d = ymd_to_ord(self) - ymd_to_ord(dt)

  #[These can't overflow, since the values are
    normalized.  At most this gives the number of
    seconds in one day. ]#
  template diff(a, b: datetime; attr): SomeInteger =
    a.attr - b.attr
  template diff(attr): untyped = diff(self, dt, attr)

  let delta_s = diff(hour) * 3600 +
                diff(minute) * 60 +
                diff(second)

  let delta_us = diff microsecond
  result = newTimedelta(
    days=delta_d, seconds=delta_s, microseconds=delta_us, normalize=true)
  if not offdiff.isTimeDeltaNone:
    result = result - offdiff


# Miscellaneous methods.

proc flip_fold(dt: datetime): datetime =
  newDatetime(dt, isfold = bool dt.fold)

proc get_flip_fold_offset(dt: datetime): timedelta =
  let flip_dt = flip_fold(dt)
  result = flip_dt.utcoffset

proc pep495_eq_exception(self, other: datetime, offset_self, offset_other: timedelta): bool =
  ## PEP 495 exception: Whenever one or both of the operands in
  ## inter-zone comparison is such that its utcoffset() depends
  ## on the value of its fold attribute, the result is False.  ## 
  ## Return 1 if exception applies, 0 if not,  and -1 on error.
  var flip_offset = get_flip_fold_offset(self)
  if not(flip_offset @= offset_self) and
      flip_offset != offset_self:
    result = true
    return
  flip_offset = get_flip_fold_offset(other)
  if not(flip_offset @= offset_other) and
      (flip_offset != offset_other):
    result = true

type
  CmpOp = enum
    coEQ
    coLT
    coLE

func cmp(val1, val2: DateTime, op: CmpOp): bool =
  case op
  of coEQ: (val1) == (val2)
  of coLT: (val1) < (val2)
  of coLE: (val1) <= (val2)

proc cmp(self; other: datetime, op: CmpOp): bool =
  if self.tzinfo @= other.tzinfo:
    return cmp(self.asNimDatetime, other.asNimDatetime, op)
  let
    offset1 = self.utcoffset()
    offset2 = other.utcoffset()
  #[If they're both naive, or both aware and have the same offsets,
    we get off cheap.  Note that if they're both naive, offset1 ==
    offset2 == Py_None at this point.]#
  template chkRetEqExc =
    let ex = pep495_eq_exception(self, other, offset1, offset2)
    if ex:
      result = true
  if (offset1 @= offset2) or offset1 == offset2:
    result = cmp(self.asNimDatetime, other.asNimDatetime, op)
    if op == coEQ and result:
      chkRetEqExc
  elif not offset1.isTimeDeltaNone and not offset2.isTimeDeltaNone:
    var delta: timedelta
    assert offset1 != offset2
    delta = self - other

    var diff = delta.days

    if diff == 0:
      diff = delta.seconds or delta.microseconds
    
    if op == coEQ and diff == 0:
      chkRetEqExc
  elif op == coEQ:
    result = false
  else:
    raise newException(TypeError, "can't compare offset-naive and " &
                                  "offset-aware datetimes")

proc `==`*(self; dt: datetime): bool = cmp(self, dt, coEQ)
proc `<=`*(self; dt: datetime): bool = cmp(self, dt, coLE)
proc `<`* (self; dt: datetime): bool = cmp(self, dt, coLT)
