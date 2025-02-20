
import std/math  # math.round

template chkAsPy[F](x: F) =
  ## used to keep along with Python's error handle
  ## check if x can be converted to PyLong
  template err(f) = raise newException(ValueError, "cannot convert float " & f & " to integer")
  case x.classify
  of fcNan: err "NaN"
  of fcInf, fcNegInf: err "infinity"
  else: discard

func round*[F: SomeFloat](x: F): F =
  ## if two multiples are equally close, rounding is done toward the even choice
  ##   a.k.a.round-to-even
  ## 
  ## .. hint:: Nim's `round` in `std/math` just does like C's round
  ## 
  runnableExamples:
    assert round(6.5) == 6
    assert round(7.5) == 8
  result = math.round(x)
  if abs(x-result) == 0.5:
    # halfway case: round to even
    result = 2.0*round(x/2.0)

    # return PyLong_FromDouble....
    result.chkAsPy
