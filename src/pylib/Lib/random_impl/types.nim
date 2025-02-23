
import std/random

type
  PyRandom* = ref object
    state: Rand

template newPyRandom(r: Rand): PyRandom = PyRandom(state: r)

proc Random*(): PyRandom = newPyRandom initRand()
proc Random*(x: int64): PyRandom = newPyRandom initRand(x)

type PyRandomState* = Rand  ## unstable.
using self: PyRandom
proc getstate*(self): PyRandomState = self.state
proc getmstate*(self): var PyRandomState =
  ## unstable. inner. Do not use
  self.state
proc setstate*(self; state: PyRandomState) = self.state = state

