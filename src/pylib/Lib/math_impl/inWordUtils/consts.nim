

import ../constsUtils

genWithArg BIAS, 127, 1023  ## 2^{k-1} - 1, here, k = 8, 11
genWithArg MAX_SUBNORMAL_EXPONENT, -127, -1023  ## 0 - BIAS
genWithArg MIN_SUBNORMAL_EXPONENT, -149, -1074 ## 1-BIAS-N_frac = -(BIAS+(52-1)) = -(1023+51) = -1074
genWithArg MAX_EXPONENT, 127, 1023
##  maxExponent F - 1 = (MAX - 1) - BIAS
## = 254 - BIAS = 127 or 2046 - BIAS = 1023


genWithBracket CLEAR_EXP_MASK, 32895, 2148532223
## 0b1_00000000_1111111 => 32895
## 0b1_00000000000_11111111111111111111 => 2148532223


genWithBracket SET_EXP_MASK, 16256, 1071644672
## mask whose exponent is equal to 126, 1022 a.k.a. (BIAS-1):
## 0b0_01111110_0000000 => 16256
## 0b0_01111111110_00000000000000000000 => 1071644672

genWithBracket EXP_MASK, 0x7f80, 0x7ff00000
## HIGH_WORD_EXPONENT_MASK:
## 0b0_11111111_0000000
## 0b0_11111111111_00000000000000000000

genWithBracket HighWordFracBits, 7, 20
genWithBracket MantissaDigits, 23, 52
## mantissaDigits F - 1
