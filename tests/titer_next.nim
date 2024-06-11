
test "iter/next":

  let ls = list([1])

  for i in iter(ls): check i == 1
  for i in iter(ls): check i == 1

  let it = iter(ls)

  check next(it) == 1

  expect StopIteration:
    discard next(it)

  checkpoint "dict"

  let d = dict(a=1)
  let dit = iter(d)
  for i in dit:
    check i == "a"
