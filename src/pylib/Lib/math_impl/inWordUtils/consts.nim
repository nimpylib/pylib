

template genBody(F, v32, v64): untyped =
  when F is float64: v64
  else: v32

template gen(sym, v32, v64){.dirty.} =
  template sym*[F](_: typedesc[F]): F = genBody(F, v32, v64)

gen BIAS, 127, 1023  ## 2^{k-1} - 1, here, k = 8, 11
gen MAX_SUBNORMAL_EXPONENT, -127, -1023  ## 0 - BIAS
gen MIN_SUBNORMAL_EXPONENT, -149, -1074 ## 1-BIAS-N_frac = -(BIAS+(52-1)) = -(1023+51) = -1074
gen MAX_EXPONENT, 127, 1023
##  maxExponent F - 1 = (MAX - 1) - BIAS
## = 254 - BIAS = 127 or 2046 - BIAS = 1023


template genMask(sym, v32, v64){.dirty.} =
  template sym*[F]: untyped = genBody(F, v32, v64)

genMask CLEAR_EXP_MASK, 32895, 2148532223
## 0b1_00000000_1111111 => 32895
## 0b1_00000000000_11111111111111111111 => 2148532223


genMask SET_EXP_MASK, 16256, 1071644672
## mask whose exponent is equal to 126, 1022 a.k.a. (BIAS-1):
## 0b0_01111110_0000000 => 16256
## 0b0_01111111110_00000000000000000000 => 1071644672

genMask EXP_MASK, 0x7f80, 0x7ff00000
## HIGH_WORD_EXPONENT_MASK:
## 0b0_11111111_0000000
## 0b0_11111111111_00000000000000000000

genMask HighWordFracBits, 7, 20
genMask MantissaDigits, 23, 52
# mantissaDigits F - 1
