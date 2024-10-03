

const
  MAX_GAMMA_X* = 171.62437695630272  ##[
    in range of 171.6243769563027{2,3}

    tgamma(171.62437695630272) == 1.7976931348622299e+308
    tgamma(171.62437695630273) == inf

got via this:

```python
# in 1/10
from math import ulp, inf
from ctypes import cdll, c_double
tgamma = cdll['libm.so.6'].tgamma
tgamma.argtypes = (c_double,)
tgamma.restype = c_double
Base = 171.6
pre =    0.1
x = Base
while pre > ulp(x):
    if tgamma(x) == inf:
        x -= pre
        pre /= 10
    x += pre
print("MAX_GAMMA_X", x)
print("precision", pre)

.. hint:: CPython's currently only implements
  as if using MAX_GAMMA_X = 200.0 and MIN_GAMMA_X = -200.0,
  which volatiles the result above.
  See `pylib#38<https://github.com/nimpylib/pylib/issues/38>`_ for details.

```
  ]##

  MIN_GAMMA_X* = -177.7807064574755  ##[
    in range of -177.780706457475{5,7}

    tgamma(-177.7807064574755) == 5e-324
    tgamma(-177.7807064574757) == 0.0
  ]##

# I found stdlib-js/gamma uses following values:
# 171.61447887182298
# -170.5674972726612
# But what I tested using SymPy was different.
# If SymPy is right and my method is so,
# then the old values are uncorrect and shall not be used,
#  as the old checking range for zero/inf result is bigger.
#  (it doesn't matter if that was smaller)
# So I change to use current values.

type GammaError* = enum
  geOk
  geDom = "x in {0, -1, -2, ...}" ##[ when .
Infinity discontinuity,
which shall produce `Complex Infinity` in SymPy and
means domain error]##
  geOverFlow = "x > " & $MAX_GAMMA_X & ", result overflow as inf"
  geUnderFlow = "x < " & $MIN_GAMMA_X & ", result underflow as `-0.0` or `0.0`."
  geZeroCantDetSign = "`x < -maxSafeInteger`(exclude -inf), " &
    "can't detect result's sign"   ## `x` losing unit digit, often not regard as an error
  geGotNegInf = "x == -inf"  ## this is made as a enumerate item as different languages'
                             ## implementation has different treatment towards -inf

const
  DEMsg = "math domain error"
  REMsg = "math range error"

template raiseDomainErr* =
  bind DEMsg
  raise newException(ValueError, DEMsg)

template raiseDomainErr*(details: string) =
  bind DEMsg
  raise newException(ValueError, DEMsg & ": " & details)

template raiseRangeErr* =
  bind REMsg
  raise newException(OverflowDefect, REMsg)

template raiseRangeErr*(details: string) =
  bind REMsg
  raise newException(OverflowDefect, REMsg & ": " & details)

func mapRaiseGammaErr*(err: GammaError) =
  case err
  of geOverFlow, geUnderFlow:
    raiseRangeErr $err
  of geDom, geGotNegInf:
    raiseDomainErr $err
  of geOk, geZeroCantDetSign: discard
