
import std/macros
import ./frame
export frame
import ./funcSignature
export funcSignature

template emptyn: NimNode = newEmptyNode()

type
  PyFuncBodyProcesser = concept var self  ## One implememted is 
                                          ## `PyAsgnRewriter` in ./frame
                                          ## while its parsePyBody is in ./tonim
    parsePyBody(self, NimNode) is NimNode


proc defImpl*(signature, body: NimNode, parser: var PyFuncBodyProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode
  ## if `signature` is of arrow expr (like f()->int), then def_restype is ignored
proc asyncImpl*(defsign, body: NimNode, parser: var PyFuncBodyProcesser): NimNode

#[
proc tryHandleNestedDef(res: var NimNode, c: NimNode, parser): bool =
  template withStack(mparser; doSth) =
    mparser.push()
    doSth
    mparser.pop()

  let s = $c[0]
  if s == "def":
    parser.withStack:
      res.add defImpl(c[1], c[2], parser=parser) 
    return true
  if s == "async":
    parser.withStack:
      res.add asyncImpl(c[1], c[2], parser=parser)
    return true
]#

proc defAux*(signature, body: NimNode,
            deftype = ident"untyped",
            parser: var PyFuncBodyProcesser;
            procType = nnkTemplateDef, pragmas = emptyn): NimNode =

  let tup = parseSignature(signature, deftype=deftype)
  let
    name = tup.name
    params = tup.params
  let nbody = parser.parsePyBody body
  newProc(name, params, nbody, procType, pragmas) 

proc defImpl(signature, body: NimNode, parser: var PyFuncBodyProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode =
  defAux(signature, body, parser=parser, deftype=deftype, procType=procType, pragmas=pragmas)

proc asyncImpl(defsign, body: NimNode; parser: var PyFuncBodyProcesser): NimNode =
  let 
    pre = defsign[0]
    signature = defsign[1]
  expectIdent(pre,"def")
  let
    apragma = newNimNode(nnkPragma).add(ident"async")
    restype = newNimNode(nnkBracketExpr).add(ident"Future", ident"void")
  defImpl(signature, body, parser=parser, pragmas=apragma, deftype=restype)
