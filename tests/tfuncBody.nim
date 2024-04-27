
test "rewrite in `def`":
  var c: int
  # the following is typical Python code, with `check(x)` meaning assert.
  def f(a, b):
    c = a + b
    return c 
  check(f(1, 2) == 3)
  check(c == 0)
  def inc_global():
    global c
    c += 1
  inc_global()
  check(c == 1)

