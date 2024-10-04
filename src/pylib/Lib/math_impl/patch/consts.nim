 
import ../constsUtils

const
  Pinf* = Inf
  Ninf* = NegInf

  EULER* = ## euler_gamma
    0.577215664901532860606512090082402431042
  SQRT_TWO_PI* =  ## `sqrt(2*PI)` <-> `sqrt(TAU)`
    2.506628274631000502415765284811045253

genWithArg maxSafeInteger, 16777215.0, 9007199254740991.0
## 2**53 - 1
## 2**24 - 1
