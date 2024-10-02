

import ./float_view
import ./indices

proc fromWords*(high, low: uint32): float =
  when nimvm:
    let u = (uint64(high) shl 32) or uint64(low)
    result = cast[float](u)
  else:
    init64FloatView FLOAT64_VIEW, UINT32_VIEW
    accessHighLow:
      UINT32_VIEW[HIGH] = high
      UINT32_VIEW[LOW]  = low
    return FLOAT64_VIEW[0]

proc fromWords*(high, low: uint16): float32 =
  when nimvm:
    let u = (high.uint32 shl 16) or low.uint32
    result = cast[float32](u)
  else:
    init32FloatView FLOAT32_VIEW, UINT16_VIEW
    accessHighLow:
      UINT16_VIEW[HIGH] = high
      UINT16_VIEW[LOW]  = low
    return FLOAT32_VIEW[0]

when isMainModule:
  assert 0 == fromWords(0u32, 0u32)
  assert -3.141592653589793 == fromWords( 3221823995u32, 1413754136u32 )
  assert NegInf == 1/fromWords( 2147483648u32, 0u32 )
  import std/math
  assert isNaN fromWords( 2146959360u32, 0 )
  assert Inf == fromWords( 2146435072u32, 0 )
  assert NegInf == fromWords( 4293918720u32, 0 )

#[
{.emit: """
function fromWords( high, low ) {
    const FLOAT64_VIEW = new Float64Array( 1 );
    const UINT32_VIEW = new Uint32Array( FLOAT64_VIEW.buffer );
    const HIGH = indices.HIGH;
    const LOW = indices.LOW;
	UINT32_VIEW[ HIGH ] = high;
	UINT32_VIEW[ LOW ] = low;
	return FLOAT64_VIEW[ 0 ];
""".}
}]#

