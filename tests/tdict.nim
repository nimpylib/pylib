
test "dict":
  var d = dict(k=1)
  var dd = d.copy()
  check d["k"] == 1

  d.update(k=3)
  d.update([("k2", 2)])

  check len(d) == 2

  check len(dd) == 1