

from ../../Lib/math_impl/errnoUtils import prepareRWErrno, setErrno, setErrno0, isErr, isErr0, ERANGE, EDOM

const
  Py_HUGE_VAL = Inf  # As Nim alreadly uses Infinity, so the host system shall always support `INFINITY`, not just HUGE_VAL 


proc Py_ADJUST_ERANGE1*(x: float) {.inline.} =
  ##  Py_ADJUST_ERANGE1(x)
  ##  Py_ADJUST_ERANGE2(x, y)
  ##  Set errno to 0 before calling a libm function, and invoke one of these
  ##  macros after, passing the function result(s) (_Py_ADJUST_ERANGE2 is useful
  ##  for functions returning complex results).  This makes two kinds of
  ##  adjustments to errno:  (A) If it looks like the platform libm set
  ##  errno=ERANGE due to underflow, clear errno. (B) If it looks like the
  ##  platform libm overflowed but didn't set errno, force errno to ERANGE.  In
  ##  effect, we're trying to force a useful implementation of C89 errno
  ##  behavior.
  ##  Caution:
  ##     This isn't reliable.  C99 no longer requires libm to set errno under
  ##         any exceptional condition, but does require +- HUGE_VAL return
  ##         values on overflow.  A 754 box *probably* maps HUGE_VAL to a
  ##         double infinity, and we're cool if that's so, unless the input
  ##         was an infinity and an infinity is the expected result.  A C89
  ##         system sets errno to ERANGE, so we check for that too.  We're
  ##         out of luck if a C99 754 box doesn't map HUGE_VAL to +Inf, or
  ##         if the returned result is a NaN, or if a C89 box returns HUGE_VAL
  ##         in non-overflow cases.
  ##
  if isErr0:
    if x == Py_HUGE_VAL or x == -Py_HUGE_VAL:
      setErrno ERANGE
  elif isErr(ERANGE) and x == 0.0:
    setErrno0

proc Py_ADJUST_ERANGE2*(x, y: float) {.inline.} =
  if x == Py_HUGE_VAL or x == -Py_HUGE_VAL or y == Py_HUGE_VAL or y == -Py_HUGE_VAL:
    if isErr0:
      setErrno ERANGE
  elif isErr ERANGE:
    setErrno0

