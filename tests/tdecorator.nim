
test "decorator":
  class O:
    @staticmethod
    def sm():
      return 1
    @classmethod
    def cm(cls):
      check(cls == O)
      return 2
  
  check(O.sm()==1)
  check(O.cm()==2)

test "custom decorator":
  type
    O = ref object
    Func = proc(): int
  var glob = 0

  def as_is(f: Func) -> Func:
    return f

  def inc_global(f: Func) -> Func:
    global glob
    glob = 1
    return f
  tonim:
    @as_is
    def f() -> int:
      return 3
    @inc_global
    def g() -> int:
      return 2
  
  check(f() == 3)
  check(g() == 2)
  check(glob == 1)
