


import ../inWordUtilsMapper
wu_import indices
wu_import float_view
wu_import consts


func getHighWord(x: float): uint32 =
  when nimvm:
    let u = cast[uint64](x)
    accessHighLow:
      result = cast[uint32](u shr 32)
  else:
    init64FloatView FLOAT64_VIEW, UINT32_VIEW
    FLOAT64_VIEW[0] = x
    accessHighLow:
      result = UINT32_VIEW[HIGH]

func getHighWord(x: float32): uint16 =
  when nimvm:
    let u = cast[uint32](x)
    accessHighLow:
      result = cast[uint16](u shr 16)
  else:
    init32FloatView FLOAT32_VIEW, UINT16_VIEW
    FLOAT32_VIEW[0] = x
    accessHighLow:
      result = UINT16_VIEW[HIGH]

func exponent*[F: SomeFloat](x: F): BiggestInt =
  type Res = BiggestInt
  var high = getHighWord(x).Res
  high = (high and EXP_MASK[F]()) shr HighWordFracBits[F]
  (high - Res BIAS F)
