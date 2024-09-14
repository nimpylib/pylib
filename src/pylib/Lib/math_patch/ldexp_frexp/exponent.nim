

import ./indices, ./float_view, ./consts

const EXP_MASK = 0x7ff00000
## FLOAT64_HIGH_WORD_EXPONENT_MASK

func getHighWord(x: float): uint32 =
  init64FloatView FLOAT64_VIEW, UINT32_VIEW
  FLOAT64_VIEW[0] = x
  accessHighLow:
    result = UINT32_VIEW[HIGH]


func exponent*(x: float): BiggestInt =
  var high = getHighWord(x).BiggestInt
  high = (high and EXP_MASK) shr 20
  (high - BIAS)
