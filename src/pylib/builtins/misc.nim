
template id*(x): int =
  runnableExamples:
    let a = 1.0
    var b = 1
    assert id(a) != id(b)
    # not the same as Python's (Python's small int is stored in pool)
    block:
      var a,b = 1
      assert id(a) != id(b)
  cast[int](
    when NimMajor > 1: x.addr
    else: x.unsafeAddr
  )
