# From https://github.com/Yardanico/nim-snippets/blob/master/unpack_macro.nim
import std/macros

proc unpackImpl(data: NimNode, values: NimNode): NimNode =
  # If we have only 1 value - we got number of variables to unpack
  let lenPresent = values.len == 1 and values[0].kind == nnkIntLit
  result = nnkStmtList.newTree()
  # we don't need to make a copy of the value if it's already a symbol
  let nameIdent = if data.kind == nnkSym:
    data
  # create a new variable
  else:
    var sym = genSym(nskLet, "data")
    result.add quote do:
      let `sym` = `data`
    sym

  if lenPresent:
    var data = nnkPar.newTree()
    let len2unpack = values[0].intVal
    if not(len2unpack > 0):
      error"Length to unpack must be a non-zero positive integer"
    for ind in 0 ..< len2unpack:
      data.add quote do:
        `nameIdent`[`ind`]

    result.add data

  else:
    var valIdx = 0 # current data index, needed for handling *
    var backwards = false # we need to use ^ after we find an *
    for i, val in values:
      # _ usually means "we don't want that value"
      if val == ident"_":
        discard
      # Python-like * in tuple unpacking
      elif val.kind == nnkPrefix and val[0] == ident"*":
        let valName = val[1]
        # handle *_ (yes it's valid in Python too)
        let needGenerate = valName != ident"_"
        # get how much variables we have till the end (+1)
        let ends = values.len - i
        # starting from the next value we'll do backwards indexing
        backwards = true
        # let `valName` = `nameIdent`[`valIdx` .. ^`ends`]
        if needGenerate:
          result.add newLetStmt(
            valName,
            nnkBracketExpr.newTree(
              nameIdent,
              nnkInfix.newTree(
                ident"..",
                newIntLitNode(valIdx),
                nnkPrefix.newTree(
                  ident"^",
                  newIntLitNode(ends)
                )
              )
            )
          )
        # update the value index
        valIdx = ends
      else:
        if not backwards:
          result.add quote do:
            let `val` = `nameIdent`[`valIdx`]
        else:
          result.add quote do:
            let `val` = `nameIdent`[^`valIdx`]
      # with backwards we decrement towards the end,
      # increment otherwise
      valIdx += (if backwards: -1 else: 1)

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