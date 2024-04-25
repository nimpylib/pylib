##[ python's def and async def

support:
  - param
  - param: type
  - param = defval
  - `*args`
  - -> restype
  - """doc-str""" or "doc-str"
  - nested def or async def
  
limits:
  - `*args` can only contain one type's arguments
  - can't combine type and defval i.e. `param: type = defval` is unsupported
  - for async def, only `-> Future[void]` can be omitted. Refer to std/asyncmacro for details
  - variables must be declared using `let`/`var`/`const` (this can be solved but is unnecessary)
  
unsupport:
  - generator (yield within def)  *TODO*
  - `**kws`
  - `*` and `/` in parameters-list
see codes in `runnableExamples` for more details
]##

#[def has AST structure like this:
  Command
    Ident !"def"
    Call
      Ident !"argument"
      Ident !"second_argument"
      ExprEqExpr
        Ident !"default_arg"
        FloatLit 0.0
    StmtList
      procedure body here
]#

import std/macros
template emptyn: NimNode = newEmptyNode()
proc defImpl*(signature, body: NimNode, pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode
  ## if `signature` is of arrow expr (like f()->int), then def_restype is ignored
proc asyncImpl*(defsign, body: NimNode): NimNode


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
  let name = name_params[0]
  var params = @[restype]
  parseParams(params, name_params, def_argtype=deftype, start=1)
  result.name = name
  result.params = params


proc tryHandleDocStr(res: var NimNode; n: NimNode): bool =
  if n.kind in nnkStrLit..nnkTripleStrLit: 
    res.add newCommentStmtNode($n)
    return true

proc parseNestedDef(c: NimNode): NimNode =
  case $c[0]
    of "def": defImpl(c[1], c[2]) 
    of "async": asyncImpl(c[1], c[2])
    else: c

proc parseBody*(body: NimNode): NimNode =
  result = newStmtList()
  let start =
    if result.tryHandleDocStr body[0]: 1
    else: 0
  for i in start..<body.len: # for nested [async] def
    let ele = body[i]
    if ele.kind == nnkCommand:
      result.add parseNestedDef ele
    else:
      result.add ele

proc defAux(signature, body: NimNode,
            deftype = ident"untyped",
            procType = nnkTemplateDef, pragmas = emptyn): NimNode =

  let tup = parseSignature(signature, deftype=deftype)
  let
    name = tup.name
    params = tup.params
  let nbody = parseBody body
  newProc(name, params, nbody, procType, pragmas) 

macro define*(signature, body): untyped =
  ## almost the same as `def`, but is for `template` instead of `proc`
  ##
  ## XXX: nesting `define` is not allowed. If wanting, use `template`
  runnableExamples:
    define templ(a): a+1  # note template has no implicit `result` variable
    assert templ(3) == 4
  defAux(signature, body, deftype=ident"untyped", procType=nnkTemplateDef)

proc defImpl(signature, body: NimNode, pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode =
  defAux(signature, body, deftype, procType, pragmas)

macro def*(signature, body): untyped =
  runnableExamples:
    def add(a,b): return a + b # use auto as argtype and restype
    def addi(a: int, b = 1) -> int: return add(a, b)
    assert addi(3) == 4
    def nested(a):
      def closure():
        return a
      return closure
    assert nested(3)() == 3
    def max(a, b, *args):
      "This is doc-str: a python-like `max`"
      def max2(a,b):
        if a>b: return a
        else: return b
      result = max2(a, b)
      for i in args:
        result = max2(result, i)
      return result
    assert max(1,4,2,5,0) == 5
  defImpl(signature, body)


proc asyncImpl(defsign, body: NimNode): NimNode =
  let 
    pre = defsign[0]
    signature = defsign[1]
  expectIdent(pre,"def")
  let
    apragma = newNimNode(nnkPragma).add(ident"async")
    restype = newNimNode(nnkBracketExpr).add(ident"Future", ident"void")
  defImpl(signature, body, apragma, restype)

macro async*(defsign, body): untyped =
  ## `async def ...`
  runnableExamples:
    import std/async
    async def af():
      discard "no restype mean Future[void]"
    async def afi() -> Future[int]:
      return 3
    when defined(js):
      await af()
      echo await afi()
    else:
      import std/asyncdispatch
      waitFor af()
      assert 3 == waitFor(afi())
  asyncImpl defsign, body

