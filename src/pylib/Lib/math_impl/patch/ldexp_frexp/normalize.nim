
from std/math import classify, FloatClass

const SCALAR = 4503599627370496.0  ## 1 shl 52

proc normalize*(x: float): (float, int){.noInit.} =
  let fc = classify(x)
  case fc
  of fcNan, fcInf, fcNegInf:
    (x, 0)
  of fcSubNormal:
  #elif ( x != 0.0 and abs( x ) < FLOAT64_SMALLEST_NORMAL ):
    (x * SCALAR, -52)
  else:
    (x, 0)
