
import std/macros

template emptyn: NimNode = newEmptyNode()
proc parseParams(
  resParams: var seq[NimNode], params: NimNode, def_argtype = ident"untyped",
    start=0) =
  let slen = params.len
  for i in start ..< slen:
    let param = params[i]
    var
      pname: NimNode
      typ = def_argtype
      val = emptyn
    case param.kind
    of nnkIdent: # a
      pname = param
    of nnkExprEqExpr: # a = val
      pname = param[0]
      val = param[1]
    of nnkExprColonExpr: # a: typ
      pname = param[0]
      typ = param[1]
    of nnkPrefix: # *args or **kws(can't impl!)
      pname = param[1]
      case $param[0]
      of "*":
        typ = newNimNode(nnkBracketExpr).add(ident"varargs", def_argtype)
      of "**":
        error"can't implment **kws"
      else:
        error "bad syntax, only *arg and **kw shall appear"
    else:
      error "unknown ast " & $param.kind

    resParams.add newIdentDefs(
            pname # name
           ,typ   # type
           ,val   # default value # can be omitted as empty node is default value
    )

proc splitArrow(signature: NimNode; name_params, restype: var NimNode) =
  if signature.kind == nnkInfix:
    expectIdent(signature[0], "->")
    name_params = signature[1]
    restype = signature[2]


func addGenericParam(generics: var NimNode, it: NimNode) =
  var typ: NimNode
  case it.kind
  of nnkIdent:         typ = newIdentDefs(it, emptyn, emptyn)
  of nnkExprColonExpr: typ = newIdentDefs(it[0], it[1], emptyn)
  of nnkExprEqExpr:    typ = newIdentDefs(it[0], emptyn, it[1])
  else:
    error "The generics format like `T` or `T: int` or `T = int` are supported, " &
      " things like `T: int = int` cannot be parsed by Nim", it
  generics.add typ

func newGenericsTree*: NimNode = newNimNode nnkGenericParams

func parseGenericParams*(generics: var NimNode, params: NimNode): NimNode =
  if generics.len == 0:
    generics = newGenericsTree()
  result = params[0]
  for i in 1..<params.len:
    generics.addGenericParam params[i]
  if generics.len == 0:
    generics = emptyn

func parseBracketGenericParams*(generics: var NimNode, params: NimNode): NimNode =
  ## returns name
  expectKind params, nnkBracketExpr
  parseGenericParams(generics, params)



proc parseSignature*(
  generics: var NimNode,
  signature: NimNode, deftype = ident"untyped"  
    ): tuple[name: NimNode, params: seq[NimNode]] =
  ## deftype is for both params and result,
  ## but if `signature` is of arrow expr, then restype will be its rhs.
  var
    name_params = signature
    restype = deftype
  splitArrow signature, name_params, restype
  if name_params.kind == nnkIdent:
    # Nim user may write sth like `def f: xxx`
    error "SyntaxError: expected '(' after function name", name_params
  let head = name_params[0]
  result.name =
    if head.kind == nnkBracketExpr:  # generic
      parseGenericParams(generics, head)
    else: head
  var params = @[restype]
  parseParams(params, name_params, def_argtype=deftype, start=1)
  if generics.len == 0:
    generics = emptyn
  result.params = params


func newProc*(name, generics: NimNode,
    params: openArray[NimNode] = [newEmptyNode()]; body=emptyn, procType = nnkProcDef, pragmas = emptyn): NimNode =
  ## variant that accept generics
  expectKind generics, {nnkGenericParams, nnkEmpty}
  newNimNode(procType).add(
    name,
    emptyn,
    generics,
    nnkFormalParams.newTree(params),
    pragmas,
    emptyn,
    body)

func newProc*(tup: tuple[name: NimNode, params: seq[NimNode]], generics: NimNode,
    body=emptyn, procType = nnkProcDef, pragmas = emptyn): NimNode =
  ## variant that accept generics, sleamless to work with parseSignature
  newProc(tup.name, generics, tup.params, body, procType, pragmas)

proc parseSignatureNoGenerics*(
  signature: NimNode, deftype = ident"untyped"  
    ): tuple[name: NimNode, params: seq[NimNode]] =
  var tmp_generics: NimNode = newGenericsTree()
  parseSignature(tmp_generics, signature, deftype)
