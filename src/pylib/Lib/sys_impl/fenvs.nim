
import std/fenv
import ./util
import ../../pyconfig/pycore/pymath

const float_repr_style* =
  when PY_SHORT_FLOAT_REPR: "short" else: "legacy"  ##\
## .. note:: when JS, this is "legacy" but
##   currently `$float` is still of short style.
##   this only affects other function like `round(float, int)`


type FT = float
const
  float_info* = (
    max: maximumPositiveValue FT,
    max_exp: maxExponent FT,
    max_10_exp: max10Exponent FT,
    min: minimumPositiveValue FT,
    min_exp: minExponent FT,
    min_10_exp: min10Exponent FT,
    dig: digits FT,
    mant_dig: mantissaDigits FT,
    epsilon: epsilon FT,
    radix: fpRadix,
    #rounds: 1
  )  ## float_info.rounds is defined as a `getter`, see `rounds`_

when not weirdTarget:
  let fiRound = fegetround().int
  template rounds*(fi: typeof(float_info)): int =
    ## not available when nimscript
    bind fiRound
    fiRound
else:
  template rounds*(fi: typeof(float_info)): int =
    {.error: "not available for nimscript/JavaScript/compile-time".}



