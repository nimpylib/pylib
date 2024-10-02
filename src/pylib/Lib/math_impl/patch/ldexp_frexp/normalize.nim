
#from std/math import classify, FloatClass
from std/fenv import minimumPositiveValue
import ../inWordUtilsMapper
wu_import MantissaDigits from consts

template SCALAR[T](x: typedesc[T]): T =
  ## 1 shl (mantissaDigits(T) - 1)
  when T is float64: 4503599627370496.0  ## 1 shl 52
  else: 8388608'f32 ## 1 shl 23

proc normalize*[F: SomeFloat](x: F): (F, int){.noInit.} =
  if ( x != 0.0 and abs( x ) < minimumPositiveValue F ):  # subnormal
    (x * SCALAR F, -MantissaDigits F)
  else:
    (x, 0)
