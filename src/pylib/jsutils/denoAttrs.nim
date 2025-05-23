##[
  This module is intended to merge some similar code between NodeJs and Deno.

  For example,

  process.pid Deno.pid
  fs.openSync Deno.openSync
]##

import ./deno
export deno

when defined(js):
  import std/macros
  when not defined(nodejs):
    from std/strutils import `%`
  proc importByNodeOrDenoImpl(def: NimNode; nodeExpr, denoExpr: string): NimNode =
    var
      nodeExpr = nodeExpr
      denoExpr = denoExpr
    template JsExpr: NimNode =  # lazy eval on nodeExpr, denoExpr
      newLit:
        when defined(nodejs):  # fast-path when defined nodejs
          nodeExpr
        else:
          DenoDetectedJsExpr & ("?$1:$2" % [denoExpr, nodeExpr])
    template JsPragma: NimNode =  # lazy eval on `JsExpr`
      nnkExprColonExpr.newTree(ident"importjs", JsExpr)

    case def.kind
    of nnkLetSection, nnkVarSection:
      if def[0][0].kind == nnkPragmaExpr:
        def[0][0][1].add JsPragma
      else:
        def[0][0] = nnkPragmaExpr.newTree(def[0][0], nnkPragma.newTree JsPragma)
    of RoutineNodes:
      func addParamsIfNotAttr(s: var string) =
        if s[^1] == '$': s.setLen s.len-1
        else: s.add "(@)"
      nodeExpr.addParamsIfNotAttr()
      denoExpr.addParamsIfNotAttr()
      def.addPragma JsPragma
    else:
      error "only var/let and procs is supported, but got " & $def.kind, def
    def
  macro importByNodeOrDeno*(node, deno: static[string]; def) =
    ## pragma
    importByNodeOrDenoImpl(def, nodeExpr=node, denoExpr=deno)
  proc myrepr(n: NimNode): string =
    if n.kind in nnkStrLit..nnkTripleStrLit: n.strVal
    else: repr n
  proc importDenoOrImpl(def: NimNode; objInNode: string;
      denoAttr: NimNode, nodeAttr=denoAttr): NimNode =
    let
      denoAttr = myrepr denoAttr
      nodeAttr = myrepr nodeAttr
    importByNodeOrDenoImpl(def,
      nodeExpr=objInNode&'.'&nodeAttr,
      denoExpr="Deno."&denoAttr
    )

  func requireExpr(module: string): string = "require('" & module & "')"
  macro importDenoOrNodeMod*(modInNode, attr; def) =
    importDenoOrImpl(def, requireExpr $modInNode, attr)
  macro importInNodeModOrDeno*(modInNode, attrNode, attrDeno; def) =
    importDenoOrImpl(def, requireExpr $modInNode, attrDeno, attrNode)
  macro importDenoOr*(objInNode, attr; def) =
    importDenoOrImpl(def, $objInNode, attr)

  proc importNodeImpl(def: NimNode, module, symExpr: string): NimNode =
    importByNodeOrDenoImpl(def,
      requireExpr(module) & '.' & symExpr,
      "(await import('node:" & module & "'))." & symExpr
    )

  proc importDenoOrProcessAux(denoAttr, nodeAttr, def: NimNode): NimNode =
    importDenoOrImpl(def, "process", denoAttr, nodeAttr)

  macro importDenoOrProcess*(denoAttr, nodeAttr; def) =
    importDenoOrProcessAux(denoAttr, nodeAttr, def)
  macro importDenoOrProcess*(attr; def) =
    importDenoOrProcessAux(attr, attr, def)

  macro importNode*(module, symExpr; def) =
    let ssym = case symExpr.kind
    of nnkStrLit, nnkRStrLit, nnkTripleStrLit, nnkIdent: symExpr.strVal  # also allows dotExpr
    of nnkDotExpr: symExpr[0].strVal & '.' & symExpr[1].strVal
    else: error "invalid nim node type " & $symExpr.kind
    importNodeImpl(def, module.strVal, ssym)
