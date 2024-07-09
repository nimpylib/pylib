
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

proc parseSignature*(signature: NimNode, deftype = ident"untyped"
    ): tuple[name: NimNode, params: seq[NimNode]] =
  ## deftype is for both params and result,
  ## but if `signature` is of arrow expr, then restype will be its rhs.
  var
    name_params = signature
    restype = deftype
  splitArrow signature, name_params, restype

  if name_params.kind != nnkCall:
    # Nim user may write sth like `def f: xxx`
    error "SyntaxError: expected '(' after function name", name_params
  let name = name_params[0]
  var params = @[restype]
  parseParams(params, name_params, def_argtype=deftype, start=1)
  result.name = name
  result.params = params
