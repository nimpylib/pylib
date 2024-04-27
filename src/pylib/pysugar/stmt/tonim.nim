
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
import ./[pyraise, frame, pydef]

using mparser: var PyAsgnRewriter

proc tryHandleDocStr(res: var NimNode; n: NimNode): bool =
  if n.kind in nnkStrLit..nnkTripleStrLit: 
    res.add newCommentStmtNode($n)
    return true

proc parsePyBody*(mparser; body: NimNode): NimNode

proc parsePyStmt*(mparser; statement: NimNode): NimNode =
  ## Rewrites statement from Python-favor to Nim
  ## 
  ## - rewrite `raise`
  ## - assignment without declaration, with `global` statement
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
    let (varName, varValue) = (statement[0], statement[1])
    if varName.kind != nnkIdent:  # varName may be `nnkDotExpr`. e.g.`a.b=1`
      result.add statement
    # if varName != nnkIdent, then $varName is an error.
    # And, we just only care `ident`
    elif $varName in mparser:
      result.add statement
    else:
      result.add newVarStmt(varName, varValue)
      mparser.add $varName
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
      mparser.withStack:
        result.add defImpl(statement[1], statement[2], parser=mparser)
    of "async":
      mparser.withStack:
        result.add asyncImpl(statement[1], statement[2], parser=mparser)
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
  else:
    result.add statement

proc parsePyBody*(mparser; body: NimNode): NimNode =
  ## Rewrites doc-string to `CommentStmtNode` 
  ## and map each stmt with `parsePyStmt`.
  result = newStmtList()
  let start =
    if result.tryHandleDocStr body[0]: 1
    else: 0
  for i in start..<body.len:
    let ele = body[i]
    result.add mparser.parsePyStmt ele
    

template parsePyBody*(body: NimNode): NimNode =
  var parser = newPyAsgnRewriter()
  parser.parsePyBody body
