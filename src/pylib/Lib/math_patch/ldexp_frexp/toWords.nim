
import ./float_view
import ./indices

proc toWords*(x: float): (uint32, uint32) =
  FLOAT64_VIEW[ 0 ] = x
  result[0] = UINT32_VIEW[ HIGH ]
  result[1] = UINT32_VIEW[ LOW ]

proc toWords*(x: float32): (uint16, uint16) =
  FLOAT32_VIEW[ 0 ] = x
  result[0] = UINT16_VIEW[ HIGH ]
  result[1] = UINT16_VIEW[ LOW ]

when isMainModule:
  assert toWords(3.14e201) == (1774486211u32, 2479577218u32)
