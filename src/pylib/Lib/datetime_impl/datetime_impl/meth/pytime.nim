
## translated from CPython/Python/pytime.c

import ./platform_utils
when defined(js):
  import ./js/time
else:
  import ./struct_tm_decl, ./struct_tm_meth
  import ./errno_decl
  #from ./importer import raiseErrno

import ./importer
export PyTime_round_t, prTimeout, Timestamp, long

import std/math

func float_to_denominator(d: float, sec: var time_t, numerator: var long,
    idenominator: long, round: PyTime_round_t) =
  ## pytime_double_to_denominator
  ##
  ## XXX: raise OverflowDefect instead of returning -1
  let denominator = float idenominator
  var
    intpart, floatpart: float
  (intpart, floatpart) = d.splitDecimal

  floatpart *= denominator
  floatpart = round(floatpart, round)
  if floatpart >= denominator:
    floatpart -= denominator
    intpart += 1.0
  elif floatpart < 0:
    floatpart += denominator
    intpart -= 1.0
  assert 0.0 <= floatpart and floatpart < denominator

  # Nim will overflow-check time_t
  #  the following is from CPython's comments:

  #[Conversion of an out-of-range value to time_t gives undefined behaviour
    (C99 §6.3.1.4p1), so we must guard against it. However, checking that
    `intpart` is in range is delicate: the obvious expression `intpart <=
    PY_TIME_T_MAX` will first convert the value `PY_TIME_T_MAX` to a double,
    potentially changing its value and leading to us failing to catch some
    UB-inducing values. The code below works correctly under the mild
    assumption that time_t is a two's complement integer type with no trap
    representation, and that `PY_TIME_T_MIN` is within the representable
    range of a C double.

    Note: we want the `if` condition below to be true for NaNs; therefore,
    resist any temptation to simplify by applying De Morgan's laws.]#
  
  sec = time_t intpart
  numerator = long floatpart
  assert 0 <= numerator and numerator < idenominator

func object_to_denominator(obj: Timestamp, sec: var time_t, numerator: var long,
    denominator: long, round: PyTime_round_t) =
  ## pytime_object_to_denominator
  assert denominator >= 1

  when obj is float:
    let d = obj
    if d.isnan:
      numerator = 0
      raise newException(ValueError, "Invalid value NaN (not a number)")
    float_to_denominator(d, sec, numerator,
                                        denominator, round)
  else:
    sec = obj
    numerator = 0

func nPyTime_ObjectToTimeval*(
  obj: Timestamp; sec: var time_t, usec: var long,
  round: PyTime_round_t
) =
  ## PyTime_ObjectToTimeval but raise OverflowDefect instead of returning -1
  ## i.e. returns nothing.
  object_to_denominator(obj, sec, usec, SEC_TO_US, round)


when weridTarget:
  export time.nPyTime_gmtime, time.nPyTime_localtime
else:
  # L1286 _PyTime_localtime
  proc nPyTime_localtime*(t: time_t, tm: var Tm) =
    var t = t
    # as localtime_*'s first param is const pointer,
    # so it's fine to pass a local data's pointer
    when defined(windows):
      var error: int
      error = localtime_s(tm, t)
      if error != 0:
        raiseErrno()
    else:
      when defined(aix) and SIZEOF_TIME_T < 8:
        # bpo-34373: AIX does not return NULL if t is too small or too large
        if (t < -2145916800 or # 1902-01-01
            t > 2145916800): # 2038-01-01 
          errno = EINVAL
          raise newException(OverflowDefect, "localtime argument out of range")
      errno = 0
      if localtime_r(t, tm) == nil:
       if errno == 0:
         errno = EINVAL
         raiseErrno()

  proc nPyTime_gmtime*(t: time_t, tm: var Tm) =
    var t = t
    # as gmtime_*'s first param is const pointer,
    # so it's fine to pass a local data's pointer
    when defined(windows):
      let error = gmtime_s(tm, (t))
      if error != 0:
        errno = error
        raiseErrno()
    else:
      if gmtime_r((t), tm) == nil:
        when declared(EINVAL):
          if errno == 0:
            errno = EINVAL
        raiseErrno()
