
import ./assertIsLittleEndian

when defined(js):
  var HIGHv, LOWv: cint

  if isLittleEndian():
    HIGHv = 1; # second index
    LOWv = 0; # first index
  else:
    HIGHv = 0; # first index
    LOWv = 1; # second index

  let
    HIGH* = HIGHv
    LOW* = LOWv
  template accessHighLow*(body) =
    {.noSideEffect.}:
      body

else:
  const
    HIGH* = int(isLittleEndian())
    LOW* = int(not isLittleEndian())

  template accessHighLow*(body) = body