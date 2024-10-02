
import ./float_view
import ./indices

func toWords*(x: float): (uint32, uint32) =
  when nimvm:
    let u = cast[uint64](x)
    result[0] = cast[uint32](u shr 32)
    result[1] = cast[uint32](u)
  else:
    init64FloatView FLOAT64_VIEW, UINT32_VIEW
    FLOAT64_VIEW[ 0 ] = x
    accessHighLow:
      result[0] = UINT32_VIEW[ HIGH ]
      result[1] = UINT32_VIEW[ LOW ]

func toWords*(x: float32): (uint16, uint16) =
  when nimvm:
    let u = cast[uint32](x)
    result[0] = cast[uint16](u shr 16)
    result[1] = cast[uint16](u)
  else:
    init32FloatView FLOAT32_VIEW, UINT16_VIEW
    FLOAT32_VIEW[ 0 ] = x
    accessHighLow:
      result[0] = UINT16_VIEW[ HIGH ]
      result[1] = UINT16_VIEW[ LOW ]

when isMainModule:
  assert toWords(3.14e201) == (1774486211u32, 2479577218u32)
