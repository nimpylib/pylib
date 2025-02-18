
from ../Lib/math_impl/errnoUtils import prepareRWErrno, setErrno0, isErr, ERANGE
import ./pyconfig/main
import ../impure/math/dtoa
import ../impure/Python/mysnprintf

# Include/internal/pycore_pymath.h

when compileOption"threads":
  template allocImpl(T, s): untyped = cast[ptr T](allocShared(s))
  template pyfree(p) = freeShared p
else:
  template allocImpl(T, s) = cast[ptr T](alloc(s))
  template pyfree(p) = free p

template pyalloc[T](s): ptr T = allocImpl(T, s)
template pyallocStr(s): cstring = cast[cstring](pyalloc[cchar](s))
template pyfreeStr(p) = pyfree cast[ptr cchar](p)

proc round*(dd: float, ndigits: int): float =
  ##[ /* version of double_round that uses the correctly-rounded string<->double
    conversions from Python/dtoa.c */]##
  const mode = 3
  const MyBufLen = 100
  var
    mybuflen = MyBufLen
    buf, buf_end: cstring
    shortbuf: array[MyBufLen, cchar]
    mybuf: cstring = cast[cstring](addr shortbuf[0])
    decpt, sign: c_int

  Py_SET_53BIT_PRECISION_HEADER

  # round to a decimal string

  Py_SET_53BIT_PRECISION_START
  buf = dtoa(dd.cdouble, mode.cint, ndigits.cint, decpt, sign, buf_end)
  Py_SET_53BIT_PRECISION_END
  template preexit =
    freedtoa buf
  template chkNoMem(p: ptr|cstring) =
    if p.isNil:
      preexit
      raise newException(OutOfMemDefect, "")
  buf.chkNoMem

  #[Get new buffer if shortbuf is too small.  Space needed <= buf_end -
    buf + 8: (1 extra for '0', 1 for sign, 5 for exp, 1 for '\0').]#
  let buflen = cast[int](buf_end) - cast[int](buf)
  if buflen  + 8 > mybuflen:
    mybuflen = buflen + 8
    mybuf = pyallocStr mybuflen
    mybuf.chkNoMem

  # copy buf to mybuf, adding exponent, sign and leading 0
  PyOS_snprintf(mybuf, mybuflen, "%s0%se%d",
                (if sign.bool: cstring"-" else: cstring""),
                buf, cast[cint](decpt) - buflen.cint)

  # and convert the resulting string back to a double
  prepareRWErrno
  setErrno0
  Py_SET_53BIT_PRECISION_START
  result = strtod(mybuf, nil)
  Py_SET_53BIT_PRECISION_END

  if isErr(ERANGE) and abs(result) >= 1:
    raise newException(OverflowDefect, "rounded value too large to represent")

  # done computin value
  if cast[ptr cchar](mybuf) != shortbuf[0].addr:
    pyfreeStr mybuf

  preexit
