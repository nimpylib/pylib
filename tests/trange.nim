import unittest
include pylib/range

test "Range-like Nim procedure":
  # We don't need to check if iterators work because these "range" calls are
  # just templates calling toSeq(range iterator(arguments)) 
  checkpoint "One argument - stop"
  check range(0).len == 0
  check range(5) == @[0, 1, 2, 3, 4]
  checkpoint "Two arguments - start and stop"
  check range(3, 5) == @[3, 4]
  checkpoint "Negative start and positive stop"
  check range(-7, 3) == @[-7, -6, -5, -4, -3, -2, -1, 0, 1, 2]
  checkpoint "3 positive arguments"
  check range(1, 10, 3) == @[1, 4, 7]
  checkpoint "Positive start, negative stop and step"
  check range(0, -10, -2) == @[0, -2, -4, -6, -8]
  check range(5, -5, -3) == @[5, 2, -1, -4]
  checkpoint "Variables"
  let a = 10
  check range(a, a+2) == @[a, a + 1]
  checkpoint "Zero step"
  expect AssertionError:
    discard range(1, 2, 0)