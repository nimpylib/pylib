
import std/macros
import std/times
include ./common
import ./getter
import ../../timedelta_impl/[
  decl, meth]
import ../../timezone_impl/[
  decl
]
from ./importer import `@=`, ymd_to_ord, TypeError

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
    offset1 = self.utcoffset()
    offset2 = dt.utcoffset()
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
