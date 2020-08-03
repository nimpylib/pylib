import macros, strformat

# It's not actually needed here, but I'll just keep it
# so you can understand which experimental feature we're using
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
  expectLen iterable, 4
  let call = iterable[2]
  let body = iterable[^1]

  var startingValue: NimNode
  if call.len < 2:
    error("enumerate() missing required argument 'iterable'", call)
  if call.len == 2:
    startingValue = newLit(0)
  elif call.len == 3:
    startingValue = call[2]
  else:
    error(fmt"enumerate() takes at most 2 arguments ({call.len - 1} given)", call)

  result = newStmtList()
  var newFor = newTree(nnkForStmt)
  result.add newVarStmt(iterable[0], startingValue)
  body.insert(body.len, newCall(bindSym"inc", iterable[0]))
  for i in 1 .. iterable.len - 3: newFor.add iterable[i]
  newFor.add iterable[^2][1]
  newFor.add body
  result.add newFor
  result = newBlockStmt(result)
