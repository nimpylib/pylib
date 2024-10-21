

suite "rewrite as py stmt":
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

  test "rewrite raise":
    template pyexpect(exc; raise_body) =
      block:
        # HINT: `def`'s name won't be mangled bt template,
        # so there's a block
        def f():
          raise_body
        expect exc:
          f()
    pyexpect ValueError: raise ValueError("foo")
    pyexpect ValueError: raise ValueError
    let exc = newException(OSError, "foo")
    def f(): 
      raise ValueError from exc 
    try: f()
    except ValueError as e:
      check e.parent == exc

