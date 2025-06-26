
test "Range-like Nim procedure":
  # We don't need to check if iterators work because these "range" calls are
  # just templates calling @(range iterator(arguments))
  checkpoint "One argument - stop"
  check len(range(1)) == 1
  check len(range(4,0)) == 0
  check @(range(5)) == @[0, 1, 2, 3, 4]
  checkpoint "Two arguments - start and stop"
  check @(range(3, 5)) == @[3, 4]
  checkpoint "Negative start and positive stop"
  check @(range(-7, 3)) == @[-7, -6, -5, -4, -3, -2, -1, 0, 1, 2]
  checkpoint "3 positive arguments"
  check @(range(1, 10, 3)) == @[1, 4, 7]
  checkpoint "Positive start, negative stop and step"
  check @(range(0, -10, -2)) == @[0, -2, -4, -6, -8]
  check @(range(5, -5, -3)) == @[5, 2, -1, -4]
  checkpoint "Variables"
  const a = 10
  check @(range(a, a + 2)) == @[a, a + 1]
  checkpoint "Zero step"
  expect ValueError:
    discard @(range(1, 2, 0))
  checkpoint "For loop"
  var data: seq[int] = @[]
  for x in range(0, -10, -2):
    data.add(x)
  check data == @[0, -2, -4, -6, -8]
  let myrange = range(0, 41412423, 4122)
  check 11566332 in myrange
  check 1 notin myrange
  check len(myrange) == 10047
  check myrange[5123] == 21117006
  check max(myrange) == 41409612
  check min(myrange) == 0
