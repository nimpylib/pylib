
import ./stmt/unpack

macro unpack*(data: untyped, values: varargs[untyped]): untyped =
  runnableExamples:
    # Simple unpacking - you need to provide the length to unpack
    let (a, b, c) = @[1, 2, 3, 4].unpack(3)
    doAssert (a + b + c) == 6

    # When unpacking with length you get a tuple so you can assign it
    # to something like let (a, b, ...) = x later
    doAssert @[1, 2, 3, 5].unpack(2) == (1, 2)

    # You can call unpack with variable names so you don't have to provide
    # the length to unpack
    # You can also optionally use `_` for values you don't want to get
    @[1, 2, 3, 5, 6].unpack(g, x, _, _, z)
    doAssert (g + x + z) == 9

    # Finally, this macro supports Python-like star expressions
    # for variables:
    let data = @[1, 2, 3, 4, 5, 6]
    data.unpack(valA, valB, valC, *valY, valG)
    doAssert (valA + valB + valC + valG) == 12
    # For star expressions you get sequences
    doAssert valY == @[4, 5]

    data.unpack(start, *ends)
    doAssert start == 1
    doAssert ends == @[2, 3, 4, 5, 6]

    # *_ means "ignore al values until the next variable"
    data.unpack(k, r, *_, f)
    doAssert k == 1
    doAssert r == 2
    doAssert f == 6

    # You're not limited to simple expressions, you can call this
    # macro with somewhat complex expressions or variables
    let values = @[3, 2, 5, 7]
    doAssert values.unpack(4) == (3, 2, 5, 7)

    import std/strutils
    "how are you".split().unpack(ca, cb, cc)

    doAssert @[ca, cb, cc].join(", ") == "how, are, you"
  result = unpackImpl(data, values)