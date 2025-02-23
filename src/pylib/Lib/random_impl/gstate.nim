
import ./types
export types

var gRandom = Random()

template gRand*: untyped =
  bind gRandom, getmstate
  gRandom.getmstate()
