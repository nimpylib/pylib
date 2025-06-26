
##
## ## Limits
## ### global/nonlocal for nonexisting variable
## In Python using global/nonlocal to declare a new variable is allowed,
## but here it may be impossible to implement, as Nim is statically-typed, 
## we must know its type when declaring a variable,
## while getting a type from AST
## whose type is `untyped<https://nim-lang.org/docs/system.html#untyped>`_
## is almostly impossible.
## 
## ### global/nonlocal only means `not local`, with some limited checks
## - Currently using `global name`
##   where name is declared in *previous* frames is not supported
## - Currently using `nonlocal name`
##   where name is used for globals is not supported

# TODO: implement Python's nonblock scope
#
#  that's:
# ```Python
# if True: a=1
# print(a)
# ```

import std/macros
import ./pyraise, ./frame, ./pydef, ./unpack, ./decorator, ./exprRewrite, ./decl
import ./class
import ../../private/inspect_cleandoc

using mparser: var PyAsgnRewriter
proc parsePyBody*(mparser; body: NimNode): NimNode  # front decl
proc parsePyBodyWithDoc*(mparser; body: NimNode): NimNode  # front decl
proc parsePyBodyWithDoc*(mparser; body: NimNode, docNode: var NimNode): NimNode  # front decl

proc tryHandleDocStr(res: var NimNode; n: NimNode, dedent=false): bool =
  if n.kind in nnkStrLit..nnkTripleStrLit: 
    let s = $n
    res.add newCommentStmtNode(
      if dedent: `inspect.cleandoc` s
      else: s
    )
    return true

proc parsePyExpr*(mparser; exp: NimNode): NimNode =
  bind toPyExpr
  toPyExpr(mparser, exp)

template parseBodyOnlyLast(ele): NimNode =
  ## parse body only for last but apply `toPyExpr`_ for remaining
  var subStmt = newNimNode ele.kind
  let last = ele.len - 1
  for i in 0..<last:
    subStmt.add mparser.parsePyExpr ele[i]
  subStmt.add mparser.parsePyBody ele[last]
  subStmt

proc parsePyStmt*(mparser; statement: NimNode): NimNode =
  ## Rewrites statement from Python-favor to Nim
  ## 
  ## statement shall not be `nnkStmtList`
  result = newStmtList()
  template withStack(mparser; doSth) =
    mparser.push()
    doSth
    mparser.pop()
  case statement.kind
  of nnkVarSection, nnkLetSection, nnkConstSection:
    # support mixin `let/var/const`
    var nStmt = statement.copyNimNode
    for defs in statement:
      mparser.add $statement[0]
      var nDefs = defs.copyNimTree
      nDefs[^1] = mparser.parsePyExpr nDefs[^1]
      nStmt.add nDefs
    result.add nStmt
  of nnkAsgn:
    # variable assignment
    template handleVar(varName, varValue: NimNode) =
      if $varName in mparser:
        result.add newAssignment(varName, varValue)
      else:
        result.add newVarStmt(varName, varValue)
        mparser.add $varName
      
    let (varName, varValue) = (statement[0], statement[1])
    case varName.kind
    of nnkIdent:
      handleVar varName, mparser.parsePyExpr varValue
    of nnkTupleConstr:
      # no need to construct list if meeting `nnkBracket`
      unpackImplRec(data=mparser.toPyExprNoList varValue,
        symbols=varName, res=result, receiver=handleVar)
    of nnkBracketExpr:
      result.add newAssignment(mparser.parsePyExpr varName, mparser.parsePyExpr varValue)
    else:
      # varName may be `nnkDotExpr`. e.g.`a.b=1`
      result.add statement.copyNimNode.add(varName, mparser.parsePyExpr varValue)
  of nnkCommand:
    let preCmd = $statement[0]
    case preCmd
    of "global":
      let varName = $statement[1]
      if varName.onceDeclInFrames mparser:
        error "Currently using `global name` " &
          "where name is declared in previous frames is not supported"
      mparser.globals.add varName
    of "nonlocal":
      let varName = $statement[1]
      if varName in mparser.globals:
        error "Currently using `nonlocal name` " &
          "where name is used for globals is not supported"
      mparser.nonlocalAdd varName
    of "def":
      var defRe: NimNode
      mparser.withStack:
        defRe = defImpl(statement[1], statement[2], parser=mparser)
      result.add mparser.consumeDecorator(defRe)
    of "async":
      var defRe: NimNode
      mparser.withStack:
        defRe = asyncImpl(statement[1], statement[2], parser=mparser)
      result.add mparser.consumeDecorator(defRe)
    of "class":
      result.add mparser.classImpl(statement[1], statement[2], topLevel=false)
      # TODO: impl by define such class in global but mangling its name
      # It has to be global as  class's def is implemented via `method`,
      # which is only allowed at global scope 
    of "@":
      # dotted called decorator, e.g. @unittest.skipIf(COND, MSG)
      mparser.pushDecorator extractDottedCalledDecorator statement
    else:
      var cmd = newNimNode nnkCommand
      for i in statement:
        cmd.add:
          if i.kind == nnkStmtList:
            mparser.parsePyBody i
          else: mparser.parsePyExpr i
      result.add cmd
  of nnkRaiseStmt:
    result.add rewriteRaise statement
  of nnkPrefix:
    if not mparser.tryHandleDecorator statement:
      result.add statement
  of nnkStmtList:
    var nStmt = newNimNode statement.kind
    for e in statement:
      nStmt.add mparser.parsePyStmt e
    result.add nStmt
  of nnkReturnStmt, nnkDiscardStmt:
    result.add statement.copyNimNode.add(mparser.parsePyExpr statement[0])
  of nnkIfStmt, nnkWhenStmt:
    var nStmt = newNimNode statement.kind
    for branch in statement:
      nStmt.add parseBodyOnlyLast branch
    result.add nStmt
  of nnkOfBranch, nnkBlockStmt,
      RoutineNodes:
    result.add parseBodyOnlyLast statement
  of nnkTryStmt:
    var nStmt = newNimNode statement.kind
    expectKind statement[0], nnkStmtList
    nStmt.add mparser.parsePyBody statement[0]
    var excBranch = statement[1]
    let nExcBranchStmts = mparser.parsePyBody excBranch[^1]
    let first = excBranch[0]
    proc errNotParenExcs(where: NimNode) =
      error "SyntaxError: multiple exception types must be parenthesized", where
    func newExceptBranch(excs, body: NimNode): NimNode =
      result = newNimNode nnkExceptBranch
      for e in excs:
        result.add e
      result.add body
    if first.kind == nnkTupleConstr:
      # except (exc, ...) -> except exc, ... as Nim disallows the former.
      let excs = first
      if excBranch.len != 2:
        errNotParenExcs excs
      excBranch = newExceptBranch(excs, nExcBranchStmts)
      nStmt.add excBranch
    elif first.kind == nnkInfix and first[0].eqIdent"as":
      if first[1].kind != nnkTupleConstr:
        errNotParenExcs first[2]

      let exc = first[2]
      var nBody = newStmtList(newLetStmt(exc, newCall(bindSym"getCurrentException")))
      for i in nExcBranchStmts: nBody.add i

      var nExcBranch = newExceptBranch(first[1], nBody)
      nStmt.add nExcBranch
    else:
      if mparser.noParnMultiExecInExcept:
        excBranch[^1] = nExcBranchStmts
        nStmt.add excBranch
      else:
        # before Python3.14
        error "SyntaxError: multiple exception types must be parenthesized", first
    result.add nStmt
  of nnkInfix:
    result.add statement
  of nnkCall:
    if statement[^1].kind == nnkStmtList:
      if statement.len == 2 and statement[0].kind == nnkIdent and statement[1].len == 1:
        # a: int|a: int = 1
        let tup = parseDeclWithType(statement)
        result.add rewriteDeclInStmtAux(tup.name, tup.typ, mparser.parsePyExpr tup.val)
      else:
        result.add parseBodyOnlyLast statement
    else:
      result.add mparser.callToPyExpr statement
  of nnkForStmt, nnkWhileStmt:
    result.add parseBodyOnlyLast statement
  elif statement.len == 0:
    result.add mparser.parsePyExpr statement
  else:
    # XXX: maybe no use
    var nStmt = newNimNode statement.kind

    for e in statement:
      case e.kind
      # no need to specify `nnkWhileStmt`,
      # as it's handled by branch of `of nnkStmtList` and `else`
      of nnkStmtList:
        nStmt.add mparser.parsePyBody e
      of nnkOfBranch, nnkElifBranch, nnkElse, nnkForStmt:
        result.add parseBodyOnlyLast e
      else: nStmt.add mparser.parsePyExpr e
    result.add nStmt


proc parsePyBody*(mparser; body: NimNode): NimNode =
  result = newStmtList()
  for ele in body:
    result.add mparser.parsePyStmt ele

proc parsePyBodyWithDoc*(mparser; body: NimNode): NimNode =
  result = newStmtList()
  let start =
    if result.tryHandleDocStr(body[0], mparser.dedentDoc): 1
    else: 0
  for i in start..<body.len:
    result.add mparser.parsePyStmt body[i]

proc parsePyBodyWithDoc*(mparser; body: NimNode, docNode: var NimNode): NimNode =
  ## Rewrites doc-string to `CommentStmtNode` and assign to docNode (as nnkStmtList)
  ## and map each stmt with `parsePyStmt`.
  result = newStmtList()
  docNode = newStmtList()
  let start =
    if docNode.tryHandleDocStr(body[0], mparser.dedentDoc): 1
    else: 0
  for i in start..<body.len:
    result.add mparser.parsePyStmt body[i]

template parsePyBody*(body: NimNode): NimNode =
  var parser = newPyAsgnRewriter()
  parser.parsePyBody body
