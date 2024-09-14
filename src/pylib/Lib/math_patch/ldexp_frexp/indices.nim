
import ./assertIsLittleEndian

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
