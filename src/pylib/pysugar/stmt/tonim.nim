
##
## ## Limits
## ### global/nonlocal for nonexisting variable
## In Python using global/nonlocal to declare a new variable is allowed,
## but here it may be impossible to implement, as Nim is statically-typed, 
## we must know its type when declaring a variable,
## while getting a type from AST is almostly impossible.
## 
## ### global/nonlocal only means `not local`, with some limited checks
## - Currently using `global name`
## where name is declared in previous frames is not supported
## - Currently using `nonlocal name`
## where name is used for globals is not supported

# TODO: implement Python's nonblock scope
#
#  that's:
# ```Python
# if True: a=1
# print(a)
# ```

import std/macros
import ./pyraise, ./frame, ./pydef, ./unpack, ./decorator

using mparser: var PyAsgnRewriter
proc parsePyBody*(mparser; body: NimNode): NimNode  # front decl
proc parsePyBodyWithDoc*(mparser; body: NimNode): NimNode  # front decl

proc tryHandleDocStr(res: var NimNode; n: NimNode): bool =
  if n.kind in nnkStrLit..nnkTripleStrLit: 
    res.add newCommentStmtNode($n)
    return true

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
    for defs in statement:
      mparser.add $statement[0]
    result.add statement
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
      handleVar varName, varValue
    of nnkTupleConstr:
      unpackImplRec(data=varValue, symbols=varName, res=result, receiver=handleVar)
    else:
      # varName may be `nnkDotExpr`. e.g.`a.b=1`
      result.add statement
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
      error "class in def is not supported yet"
      # TODO: impl by define such class in global but mangling its name
      # It has to be global as  class's def is implemented via `method`,
      # which is only allowed at global scope 
    else:
      var cmd = newNimNode nnkCommand
      for i in statement:
        cmd.add:
          if i.kind == nnkStmtList:
            mparser.parsePyBody i
          else: i
      result.add cmd
  of nnkRaiseStmt:
    result.add rewriteRaise statement
  of nnkPrefix:
    if not mparser.tryHandleDecorator statement:
      result.add statement
  else:
    if statement.len == 0:
      result.add statement
    else:
      var nStmt = newNimNode statement.kind
      template parseBodyOnlyLast(ele) =
        var subStmt = newNimNode ele.kind
        let last = ele.len - 1
        for i in 0..<last:
          subStmt.add ele[i]
        subStmt.add mparser.parsePyBody e[last]
        nStmt.add subStmt

      for e in statement:
        case e.kind
        # no need to specify `nnkWhileStmt`,
        # as it's handled by branch of `of nnkSmtList` and `else`
        of nnkStmtList: nStmt.add mparser.parsePyBody e
        of nnkOfBranch, nnkElifBranch, nnkElse, nnkForStmt:
          parseBodyOnlyLast e
        else: nStmt.add e
      result.add nStmt


proc parsePyBody*(mparser; body: NimNode): NimNode =
  result = newStmtList()
  for ele in body:
    result.add mparser.parsePyStmt ele

proc parsePyBodyWithDoc*(mparser; body: NimNode): NimNode =
  result = newStmtList()
  let start =
    if result.tryHandleDocStr body[0]: 1
    else: 0
  for i in start..<body.len:
    result.add mparser.parsePyStmt body[i]

proc parsePyBodyWithDoc*(mparser; body: NimNode, docNode: var NimNode): NimNode =
  ## Rewrites doc-string to `CommentStmtNode` and assign to docNode (as nnkStmtList)
  ## and map each stmt with `parsePyStmt`.
  result = newStmtList()
  docNode = newStmtList()
  let start =
    if docNode.tryHandleDocStr body[0]: 1
    else: 0
  for i in start..<body.len:
    result.add mparser.parsePyStmt body[i]

template parsePyBody*(body: NimNode): NimNode =
  var parser = newPyAsgnRewriter()
  parser.parsePyBody body
