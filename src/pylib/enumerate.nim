import macros

{.experimental: "forLoopMacros".}

macro enumerate*(iterable: ForLoopStmt): untyped =
  ## Mimics Python enumerate()
  #expandMacros:
  #  for i, x in enumerate([0, 1 , 2, 3]): echo i, "\t", x
  #
  #block:
  #  var i = 0
  #  for x in items([0, 1 , 2, 3]):
  #    echo i, "\t", x
  #    inc i
  runnableExamples:
    var a, b: int
    for i, x in enumerate([0, 1 , 2, 3]): inc a, i; inc b, x
    doAssert a == b

  expectKind iterable, nnkForStmt
  result = newStmtList()
  var body = iterable[^1]
  if body.kind != nnkStmtList: body = newTree(nnkStmtList, body)
  var newFor = newTree(nnkForStmt)
  result.add newVarStmt(iterable[0], 0.newLit)
  body.insert(body.len, newCall(bindSym"inc", iterable[0]))
  for i in 1 .. iterable.len - 3: newFor.add iterable[i]
  newFor.add iterable[^2][1]
  newFor.add body
  result.add newFor
  # result.add newCall(bindSym"reset", iterable[0])
  result = newBlockStmt(result)
