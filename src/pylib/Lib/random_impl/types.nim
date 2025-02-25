
import std/random

type
  PyRandom* = ref object of RootObj
    state: Rand

template newPyRandom(r: Rand): PyRandom = PyRandom(state: r)

proc Random*(): PyRandom = newPyRandom initRand()
proc Random*(x: int64): PyRandom = newPyRandom initRand(x)

type PyRandomState* = Rand  ## unstable.
using self: PyRandom
method getstate*(self): PyRandomState{.base.} = self.state
proc getmstate*(self): var PyRandomState =
  ## unstable. inner. Do not use
  self.state
method setstate*(self; state: PyRandomState){.base.} = self.state = state

