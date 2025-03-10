

import std/macros
import std/tables

import ./n_chainmap
export n_chainmap.`[]`, n_chainmap.contains
import ./substituteImpl
import ./template_decl

export template_decl
export initRaisesExcHandle, initIgnoreExcHandle

proc Template*(s: string): Template =
  new result
  result.`template` = s

#func substitute*(templ: Template): PyStr = str templ

proc toTableNode[K](kws: NimNode): NimNode#[Table]# =
  let kNode = ident $K
  if kws.len == 0:
    let vNode = bindSym"string"
    result = newCall:
      nnkBracketExpr.newTree(bindSym"initTable", kNode, vNode)
    return
  result = newNimNode nnkTableConstr
  for kw in kws.items:
    expectKind kw, nnkExprEqExpr
    result.add nnkExprColonExpr.newTree(
      newCall(kNode, newLit $kw[0]),
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

using oaNode: NimNode

proc formatAux(templ: NimNode; oaNode; doExc: NimNode): NimNode =
  newCall(bindSym"substituteAux",
    newCall(bindSym"$", templ),
    oaNode, doExc,
    newDotExpr(templ, ident"delimiter")
  )


template genSubstitute*(M; Key; sym; doExc){.dirty.} =
  mixin toTable
  bind bindSym, newCall
  bind formatAux, toTableNode, initChainMap
  macro sym*(templ: Template, kws: varargs[untyped]): Key =
    formatAux templ, toTableNode[Key](kws), newCall bindSym(astToStr doExc)

  macro sym*(templ: Template, mapping: M, kws: varargs[untyped]): Key =
    formatAux templ, toTableNode[Key](mapping, kws), newCall bindSym(astToStr doExc)

proc is_valid*(templ: Template): bool = isValid($templ)
iterator get_identifiersMayDup*(templ: Template): string =
  ## not dedup
  for i in getIdentifiers $templ: yield i

