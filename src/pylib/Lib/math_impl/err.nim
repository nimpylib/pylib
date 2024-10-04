

type GammaError* = enum
  geOk
  geDom = "x in {0, -1, -2, ...}" ##[ when .
Infinity discontinuity,
which shall produce `Complex Infinity` in SymPy and
means domain error]##
  geOverFlow = "x > MAX_GAMMA_X, result overflow as inf"
  geUnderFlow = "x < MIN_GAMMA_X, result underflow as `-0.0` or `0.0`."
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
