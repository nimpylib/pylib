
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
