

import std/macros

import ./frame

using mparser: var PyAsgnRewriter

proc pushDecorator*(mparser; item: NimNode) =
  ## parse `@<item>`
  var dec: Decorator
  case item.kind
  of nnkIdent, nnkDotExpr:
    dec = Decorator(name: item, called: false)
  of nnkCall:
    dec = Decorator(name: item[0], called: true, args: item[1..^1])
  else:
    error "bad decorator", item
  mparser.decorators.add dec

proc tryHandleDecorator*(mparser; statement: NimNode): bool =
  if statement[0].eqIdent "@":
    # TODO: enter a state that enforce the following stmt is decorator and
    # exit when a function definition is met.
    # Currently, something like this is still valid:
    # @a                print(1)
    # print(1)      ->  @a   
    # def f(): pass     def f(): pass
    let item = statement[1]
    mparser.pushDecorator item
    return true
  elif statement.kind == nnkDotExpr:
    #[  @module.decorator ->
DotExpr
  Prefix
    Ident "@"
    Ident "module"
  Ident "decorator"]#
    let pre = statement[0]
    if pre.kind == nnkPrefix and pre[0].eqIdent "@":
      mparser.pushDecorator newDotExpr(pre[1], statement[1])
      return true

proc unpackCall(callee: NimNode, arg: seq[NimNode]): NimNode =
  result = newCall callee
  for i in arg:
    result.add i

proc genByDecor(mparser; d: Decorator, callee: NimNode,
    originalProcDef: NimNode): NimNode =
  if d.called:
    let callDec = unpackCall(d.name, d.args)
    result = newCall(callDec, callee)
  else:
    result = newCall(d.name, callee)

proc consumeDecorator*(mparser; procDef: NimNode): NimNode =
  ## gen:
  ## ```Nim
  ## block:
  ##   `procDef`
  ##   decorator(... (`procDef`))
  ## ```
  if mparser.decorators.len == 0:
    return procDef
  var blkExpr = newStmtList()
  blkExpr.add procDef
  let procName = procDef.name
  var call = procName
  while mparser.decorators.len != 0:
    let decor = mparser.decorators.pop()
    call = mparser.genByDecor(decor, call, procDef)
  blkExpr.add call
  let blk = newBlockStmt blkExpr
  result = newLetStmt(procName, blk)

proc extractDottedCalledDecorator*(decorator: NimNode): NimNode =
  ## Extract dotted call from `decorator`.
  ## e.g. `@a.b.c(1, 2)` -> `a.b.c(1, 2)`
  ## 
  ## .. note:: Currently `decorator` is to be modified in place, while result is still returned
  expectKind decorator, nnkCall
  expectMinLen decorator, 2
  result = decorator
  var cur = decorator
  while cur[0].kind != nnkPrefix:
    cur = cur[0]
  assert cur[0][0].eqIdent "@"
  cur[0] = cur[0][1]
