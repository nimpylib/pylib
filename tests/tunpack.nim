test "unpack macro":
  block:
    let data = @[1, 2, 3, 4]
    let (a, b, c) = data.unpack(3)
    check (a + b + c) == 6

  block:
    let data = "hello"
    let (a, b, c) = data.unpack(3)
    check (a & b & c) == "hel"

  block:
    let data = @[1, 2, 3, 4, 5, 6]
    data.unpack(a, b, c, *y, g)
    check (a + b + c + g) == 12
    check y == @[4, 5]

    data.unpack(start, *ends)
    check start == 1
    check ends == @[2, 3, 4, 5, 6]

  block:
    let data = @[1, 2, 3, 4, 5, 6, 7]
    data.unpack(a, *c, d, f)
    check a == 1
    check c == @[2, 3, 4, 5]
    check d == 6
    check f == 7

  block:
    let data = @[3, 1, 4, 2, 2, 8]
    data.unpack(a, b, *_, c)
    check (a + b + c) == (3 + 1 + 8)

  block:
    type A = object
      b: seq[int]
    let c = A(b: @[1, 2, 2, 3, 4])

    c.b.unpack(a, b, *_)
    check (a + b) == 3
