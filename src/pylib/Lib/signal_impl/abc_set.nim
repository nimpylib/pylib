
import std/sets
proc add*(self: var SomeSet[int], i: int) = self.incl i

type Set*[T] = concept self
  self.add T
