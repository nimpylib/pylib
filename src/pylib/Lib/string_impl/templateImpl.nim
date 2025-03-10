

import std/macros
import std/tables

import ./n_chainmap
import ./substituteImpl
import ./template_decl

export template_decl
export raiseKeyError, noraiseKeyError, invalidFormatString, supressInvalidFormatString

proc Template*(s: string): Template =
  new result
  result.`template` = s

#func substitute*(templ: Template): PyStr = str templ

proc toTableNode[K](kws: NimNode): NimNode#[Table]# =
  if kws.len == 0:
    let
      kNode = ident $K
      vNode = bindSym"string"
    result = newCall:
      nnkBracketExpr.newTree(bindSym"initTable", kNode, vNode)
    return
  result = newNimNode nnkTableConstr
  for kw in kws.items:
    expectKind kw, nnkExprEqExpr
    result.add nnkExprColonExpr.newTree(
      newLit $kw[0],
      kw[1],
    )
  result = newCall(bindSym"toTable", result)

proc toTableNode[K](mapping: NimNode#[Mapping]#,
    kws: NimNode): NimNode#[Table]# =
  result = newCall(bindSym"toTable", mapping)
  if kws.len == 0:
    return
  let kwsVal = toTableNode[K](kws)
  result = newCall(bindSym"initChainMap",
    kwsVal,
    result
  )
  echo result.repr

using oaNode: NimNode

proc formatAux(templ: NimNode; oaNode; doExcKey, doExcFmt: NimNode): NimNode =
  newCall(bindSym"substituteAux",
    newCall(bindSym"$", templ),
    oaNode, doExcKey, doExcFmt,
    newDotExpr(templ, ident"delimiter")
  )


template genSubstitute*(M; Key; sym; doExcKey; doExcFmt){.dirty.} =
  mixin toTable
  bind formatAux, toTableNode, bindSym, initChainMap
  macro sym*(templ: Template, kws: varargs[untyped]): Key =
    formatAux templ, toTableNode[Key](kws), bindSym(astToStr doExcKey), bindSym(astToStr doExcFmt)

  macro sym*(templ: Template, mapping: M, kws: varargs[untyped]): Key =
    formatAux templ, toTableNode[Key](mapping, kws), bindSym(astToStr doExcKey), bindSym(astToStr doExcFmt)

