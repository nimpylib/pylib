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
        def[0][0] = nnkPragmaExpr.newTree(def[0][0], JsPragma)
    of RoutineNodes:
      nodeExpr.add "(@)"; denoExpr.add "(@)"  # add pattern for proc's params
      def.addPragma JsPragma
    else:
      error "only var/let and procs is supported, but got " & $def.kind, def
    def
  macro importByNodeOrDeno*(node, deno: static[string]; def) =
    ## pragma
    importByNodeOrDenoImpl(def, nodeExpr=node, denoExpr=deno)
  proc importDenoOrImpl(def: NimNode; objInNode: string; attr: NimNode): NimNode =
    var
      sAttr =
        if attr.kind in {nnkStrLit, nnkRStrLit, nnkTripleStrLit}:
          # allow using some expr that cannot be written as Nim expr
          attr.strVal
        else:
          # allow nnkCall, ident and more complex expr
          repr(attr)
    importByNodeOrDenoImpl(def,
      nodeExpr=objInNode&'.'&sAttr,
      denoExpr="Deno."&sAttr
    )
  macro importDenoOr*(objInNode, attr; def) =
    importDenoOrImpl(def, $objInNode, attr)
  macro importDenoOrProcess*(attr; def) =
    importDenoOrImpl(def, "process", attr)

  proc importNodeImpl(def: NimNode, module, sym: string): NimNode =
    importByNodeOrDenoImpl(def,
      "require('" & module & "')." & sym,
      "(await import('" & module & "'))." & sym
    )
  macro importNode*(module, sym; def) =
    importNodeImpl(def, module.strVal, sym.strVal)
