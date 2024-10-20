
import std/macros
import ./frame
export frame
import ./funcSignature
export funcSignature
import ./types
export types

template emptyn: NimNode = newEmptyNode()

proc defImpl*(signature, body: NimNode, parser: var PySyntaxProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode
  ## if `signature` is of arrow expr (like f()->int), then def_restype is ignored
proc asyncImpl*(defsign, body: NimNode, parser: var PySyntaxProcesser;
  procType=nnkProcDef): NimNode

proc parseSignatureMayGenerics*(parser: var PySyntaxProcesser;
      generics: var NimNode; signature: NimNode,
      deftype = ident"untyped",
    ): tuple[name: NimNode, params: seq[NimNode]] =
  if parser.supportGenerics:
    parseSignature(generics, signature, deftype=deftype)
  else:
    generics = emptyn
    parseSignatureNoGenerics(signature, deftype=deftype)


proc defAux*(signature, body: NimNode,
            deftype = ident"untyped",
            parser: var PySyntaxProcesser;
            procType = nnkTemplateDef, pragmas = emptyn): NimNode =
  var generics: NimNode
  let tup = parser.parseSignatureMayGenerics(generics, signature, deftype=deftype)
  let nbody = parser.parsePyBodyWithDoc body
  result = newProc(tup, generics, nbody, procType, pragmas)

proc defImpl(signature, body: NimNode, parser: var PySyntaxProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode =
  defAux(signature, body, parser=parser, deftype=deftype, procType=procType, pragmas=pragmas)

proc asyncImpl(defsign, body: NimNode; parser: var PySyntaxProcesser;
  procType=nnkProcDef): NimNode =
  let 
    pre = defsign[0]
    signature = defsign[1]
  expectIdent(pre,"def")
  let
    apragma = newNimNode(nnkPragma).add(ident"async")
    restype = newNimNode(nnkBracketExpr).add(ident"Future", ident"void")
  defImpl(signature, body, parser=parser, pragmas=apragma, deftype=restype, procType=procType)
