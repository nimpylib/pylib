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
          DenoDetectedJsExpr & ("?$1:$2" % [nodeExpr, denoExpr])
    template JsPragma: NimNode =  # lazy eval on `JsExpr`
      nnkExprColonExpr.newTree(ident"importjs", JsExpr)

    case def.kind
    of nnkLetSection, nnkVarSection:
      if def[0][0].kind == nnkPragmaExpr:
        def[0][0][1].add JsPragma
      else:
        def[0][0] = nnkPragmaExpr.newTree(def[0][0], nnkPragma.newTree JsPragma)
    of RoutineNodes:
      nodeExpr.add "(@)"; denoExpr.add "(@)"  # add pattern for proc's params
      def.addPragma JsPragma
    else:
      error "only var/let and procs is supported, but got " & $def.kind, def
    def
  macro importByNodeOrDeno*(node, deno: static[string]; def) =
    ## pragma
    importByNodeOrDenoImpl(def, nodeExpr=node, denoExpr=deno)
  proc importDenoOrImpl(def: NimNode; objInNode: string; denoAttr, nodeAttr: NimNode): NimNode =
    let
      denoAttr = repr denoAttr
      nodeAttr = repr nodeAttr
    importByNodeOrDenoImpl(def,
      nodeExpr=objInNode&'.'&nodeAttr,
      denoExpr="Deno."&denoAttr
    )
  macro importDenoOr*(objInNode, attr; def) =
    importDenoOrImpl(def, $objInNode, attr, attr)

  func requireExpr(module: string): string = "require('" & module & "')"
  macro importDenoOrNodeMod*(modInNode, attr; def) =
    importDenoOrImpl(def, requireExpr $modInNode, attr)
  macro importDenoOr*(objInNode, attr; def) =
    importDenoOrImpl(def, $objInNode, attr)

  proc importNodeImpl(def: NimNode, module, symExpr: string): NimNode =
    importByNodeOrDenoImpl(def,
      requireExpr(module) & '.' & symExpr,
      "(await import('" & module & "'))." & symExpr
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
