

import ./indices, ./float_view, ./consts

const EXP_MASK = 0x7ff00000
## FLOAT64_HIGH_WORD_EXPONENT_MASK

proc getHighWord(x: float): uint32 =
  FLOAT64_VIEW[0] = x
  UINT32_VIEW[HIGH]


proc exponent*(x: float): BiggestInt =
  var high = getHighWord(x).BiggestInt
  high = (high and EXP_MASK) shr 20
  (high - BIAS)
