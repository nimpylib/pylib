
import std/macros

import ./gstate

func newProc(name, params, body: NimNode; procType: NimNodeKind, generics: NimNode): NimNode =
  result = newNimNode(procType).add(
    name,
    newEmptyNode(),
    generics,
    params,
    newEmptyNode(),
    newEmptyNode(),
    body)

template mkExported(name: NimNode): NimNode = postfix(name, "*")

func genGblImpl(decl: NimNode): NimNode =
  result = newStmtList decl
  let name = decl.name
  var params = decl.params.copyNimTree
  assert params[1][0].eqIdent "self", $params[1][0]
  params.del 1

  const gName = "gRand"
  var body = newStmtList nnkBindStmt.newTree(bindSym(gName), name)
  var call = newCall(name, ident(gName))
  for i in 1..<params.len:
    call.add params[i][0]
  body.add call

  var gbl = newProc(name.mkExported, params, body, nnkTemplateDef, decl[2])
  result.add gbl

macro genGbl*(decl) = genGblImpl decl

macro genGbls*(decls) =
  result = newStmtList()
  for decl in decls:
    result.add genGblImpl decl
