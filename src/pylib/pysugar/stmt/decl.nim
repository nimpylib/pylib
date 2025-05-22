## `Literal[a, b]` cannot be implemented in Nim's type system (i.e. via `type Literal[...`)

import std/macros
import std/typetraits
import ../../Lib/typing_impl/easyImpl as typing

template emptyn: NimNode = newEmptyNode()
proc parseDeclWithType*(def: NimNode): tuple[name, typ, val: NimNode] =
  ## a: int     -> a int <EmptyNode>
  ## a: int = 1 -> a int 1
  expectLen def, 2
  let
    name = def[0]
    rhs = def[1]
  expectKind rhs, nnkStmtList
  expectLen rhs, 1
  let inner = rhs[0]
  let (typ, defVal) = if inner.kind == nnkAsgn: #  a: int = 1
    (inner[0], inner[1])
  else: #  a: int
    (inner, emptyn)
  result.name = name
  result.typ = typ
  result.val = defVal

# we wanna type in st of `tonimDecl` to be resolved(typed) while others are untyped,
#  so `tonimDecl` generates a call to `rewriteDecl`

proc isX(x: typedesc, typ: NimNode): bool =
  bindSym($x) == typ

proc isLiteral(typId: NimNode): bool = isX(Literal, typId)
proc isFinal(typId: NimNode): bool = isX(Final, typId)

proc ensureType(typId: NimNode): NimNode =
  if typId.kind in {nnkIdent, nnkSym, nnkClosedSymChoice} and typId.repr in ["int", "float"]:
    newDotExpr(ident"system", typId)
  elif typId.kind == nnkBracketExpr and "Literal" == (
      if typId[0].kind == nnkDotExpr: typId[0][1]  # <module>.Literal
      else: typId[0]
  ).strVal:
    typId[0]
  else:
    typId

proc newDecl(k: NimNodeKind, variable, typ, val: NimNode, defKind=nnkIdentDefs): NimNode =
  k.newTree(defKind.newTree(variable, typ, val))

proc newConstStmtWithType(name, typ, val: NimNode): NimNode =
  nnkConstSection.newDecl(name, typ, val, nnkConstDef)

proc isBracketExpr(typId: NimNode): bool =
  typId.kind == nnkBracketExpr

type DoXxx* = untyped ## Callable in form of `proc (name, typ, val: NimNode): NimNode`

template rewriteDeclImpl(variable, oriTyp, val, t: NimNode
    ,doLiteral
    ,doFinal
    ,doElse: DoXxx): NimNode {.dirty.}#[to make `quote do` work]# =
  bind isBracketExpr, ensureType, emptyn, isX, isLiteral, isFinal,
    quote, newTree, nnkStaticExpr, nnkCommand, newConstStmt
  let tBracket = isBracketExpr t 
  let (headT, baseType) = if tBracket:
    (t[0], ensureType oriTyp[1])
  else:
    (t, ensureType t)
  if isLiteral(headT):
    let nVal =
      if isBracketExpr oriTyp:
        # generate `static: assert a == 1 or a == 2` for `Literal[1, 2]`
        var chk = infix(variable, "==", oriTyp[1])
        for i in 2..<oriTyp.len:
          chk = infix(chk, "or", infix(variable, "==", oriTyp[i]))
        let oriTypRepr = repr(oriTyp)
        nnkStaticExpr.newTree newStmtList(
          newConstStmt(variable, val),
          nnkCommand.newTree(bindSym"assert", chk,
            quote do: "bad literal: " & repr(`variable`) & " expected: " & `oriTypRepr`
          ),
          variable
        )
      else: val
    doLiteral(variable, emptyn(), nVal)
  elif isFinal(headT):
    doFinal(variable, (if tBracket: baseType else: emptyn()), val)
  else:
    doElse(variable, baseType, val)

template rewriteDeclAux*(variable, oriTyp, val: NimNode, typId=oriTyp.ensureType
    ,doLiteral: DoXxx=newConstStmtWithType
    ,doFinal: DoXxx=nnkLetSection.newDecl
    ,doElse: DoXxx=nnkVarSection.newDecl): NimNode =
  ## defined as a template to simulate `doXxx` argument accepting `Curried function`
  macro rewriteDeclInner(variablem, oriTypm, valm; t: typedesc) =
    result = rewriteDeclImpl(variablem, oriTypm, valm, t,
      doLiteral, doFinal, doElse
    )
  newCall(bindSym"rewriteDeclInner", variable, oriTyp, val, typId)

proc rewriteDeclInStmtAux*(variable, oriTyp, val: NimNode, typId=oriTyp.ensureType): NimNode =
  rewriteDeclAux(variable, oriTyp, val, typId)

when isMainModule:
  macro tonimDecls(sts) =
    result = newStmtList()
    for st in sts:
      let tup = parseDeclWithType(st)
      result.add rewriteDeclInStmtAux(tup.name, tup.typ, tup.val)

  {.push used.}
  proc int(x: float) = echo 1
  expandMacros: # XXX: const stmt for Literal will be discarded (after being checked against)
  # that's, it'll won't be seen in result of `expandMacros`
   tonimDecls:
    a: typing.Final[int] = 0
    b: int = 1
    c: Final = 1
    d: Literal[2, 3] = 3
  {.pop.}

  assert not (compiles do:
   tonimDecls:
    dd: Literal[2, 3] = 1
  )

