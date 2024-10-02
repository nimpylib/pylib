
from std/math import isNaN, classify, exp

import ../inWordUtilsMapper

wu_import toWords
wu_import fromWords
wu_import CLEAR_EXP_MASK from consts

import ./exponent, ./assertIsInfinite, ./normalize


const SET_EXP_MASK = 0x3fe00000  ## Exponent equal to 1022 (BIAS-1):
                                 ## 0 01111111110 00000000000000000000 => 1071644672

func frexp*(x: float): (float, int) =
  if x == 0.0 or  # also handles -0.0
      x.isNaN or x.isInfinite:
    result = (x, 0)
    return
  let
    X = normalize(x)
    exp = exponent(X[0]) + X[1] + 1
    WORDS = toWords(X[0])
  var
    high = WORDS[0]
  type UI = typeof high
  # Clear the exponent bits within the higher order word:
  high = high and CLEAR_EXP_MASK.UI
  # Set the exponent bits within the higher order word to BIAS-1 (1023-1=1022):
  high = high or SET_EXP_MASK.UI
  let iexp = int exp
  result = (fromWords(high, WORDS[1]), iexp)

when isMainModule and defined(js):
  # for test TypedArray
  # wu_import jsTypedArray
  # func jsTypedFrexp( x: float ): TypedArray[float64]{.exportc: "frexpFF".} =
  #   let t = frexp(x)
  #   result = newFloat64Array(2)
  #   result[0] = t[0]
  #   result[1] = t[1].float64
  type JsArray = ref object of JsRoot

  func newJsArray(x: auto): JsArray{.importjs:"new Array(#)".}
  #func `[]`(self: JsArray, i: cint): auto{.importjs: "#[#]".}  ## unused
  func `[]=`(x: JsArray, i: cint, val: auto){.importjs: "#[#]=#;".}
  func jsFrexp( x: float ): JsArray{.exportc: "frexp".} =
    ## returns an JS array with a float and an integer (of course both is in fact JS's number)
    let t = frexp(x)
    result = newJsArray(2)
    result[0] = t[0]
    result[1] = t[1]

  when defined(es6):
    # for test
    {.emit: "export {frexp};".}
  else:
    {.emit: "module.exports = frexp;".}
