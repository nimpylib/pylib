test "Range-like Nim procedure":
  # We don't need to check if iterators work because these "range" calls are
  # just templates calling toSeq(range iterator(arguments))
  checkpoint "One argument - stop"
  check len(xrange(1)) == 1
  check list(xrange(5)) == @[0, 1, 2, 3, 4]
  checkpoint "Two arguments - start and stop"
  check list(xrange(3, 5)) == @[3, 4]
  checkpoint "Negative start and positive stop"
  check list(xrange(-7, 3)) == @[-7, -6, -5, -4, -3, -2, -1, 0, 1, 2]
  checkpoint "3 positive arguments"
  check list(xrange(1, 10, 3)) == @[1, 4, 7]
  checkpoint "Positive start, negative stop and step"
  check list(xrange(0, -10, -2)) == @[0, -2, -4, -6, -8]
  check list(xrange(5, -5, -3)) == @[5, 2, -1, -4]
  checkpoint "Variables"
  const a = 10
  check list(xrange(a, a + 2)) == @[a, a + 1]
  checkpoint "Zero step"
  expect ValueError:
    discard list(xrange(1, 2, 0))
  checkpoint "For loop"
  var data: seq[int] = @[]
  for x in xrange(0, -10, -2):
    data.add(x)
  check data == @[0, -2, -4, -6, -8]
  let myxrange = xrange(0, 41412423, 4122)
  check 11566332 in myxrange
  check 1 notin myxrange
  check len(myxrange) == 10047
  check myxrange[5123] == 21117006
  check max(myxrange) == 41409612
  check min(myxrange) == 0
