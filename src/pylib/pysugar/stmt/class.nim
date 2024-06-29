
import std/macros
import ./frame, ./funcSignature, ./decorator, ./tonim

template emptyn: NimNode = newEmptyNode()

proc parseDeclWithType(def: NimNode): tuple[name, typ, val: NimNode] =
  ## a: int     -> a int <EmptyNode>
  ## a: int = 1 -> a int 1
  expectLen def, 2
  let
    name = def[0]
    rhs = def[1]
  expectKind rhs, nnkStmtList
  expectLen rhs, 1
  let inner = rhs[0]
  var typ, defVal: NimNode = emptyn
  if inner.kind == nnkAsgn: #  a: int = 1
    typ = inner[0]
    defVal = inner[1]
  else: #  a: int
    typ = inner
  result.name = name
  result.typ = typ
  result.val = defVal

#proc mapSuper(nCall: NimNode): NimNode = discard

proc replaceSuperCall(n: var NimNode, defSupCls: NimNode): bool =
  template nret(cond): untyped =
    if not cond:
      return
  nret n.kind == nnkCall
  nret n[0].kind == nnkDotExpr
  let callSup = n[0][0]
  nret callSup.kind == nnkCall
  nret callSup[0].eqIdent "super"

  var supCls = defSupCls
  let cLen = callSup.len
  if cLen > 1:
    expectIdent callSup[1], "self"
  if callSup.len > 2:
    if cLen > 3: error "super(self, <SupCls>) expected, but got too many args"
    supCls = callSup[2]

  n[0][0] = newCall(supCls, ident"self")

  #let meth = n[0][1]
  #let args = n[1..^1]

  n = newCall(ident"procCall", n)
  result = true

proc recReplaceSuperCall*(n: NimNode, defSupCls: NimNode, start=0): NimNode =
  ##[ Recursively maps `super(...).f(...)`
    to `procCall(<SuperClass>(self).f(...))`

The AST map:
```
  Call
    DotExpr
      Call
        Ident "super"
        [Ident "self"]
        [<SuperClass>]
      Ident "f"
      <args>

      |
      |
      v
  
  Command
    Ident "procCall"
    Call
      DotExpr
        Call
          <SuperClass>
          Ident "self"
        Ident "f"
```  ]##
  runnableExamples:
    import std/[macros, strutils]
    macro checkSupSub(resStr: static string; b) =
      let res = recReplaceSuperCall(b, ident"SupCls")
      assert resStr == repr(res).strip(), repr(res)
      result = newStmtList()
    checkSupSub("procCall(SupCls(self).f())"):
      super().f()
    checkSupSub("procCall(SS(self).f(a, b))"):
      super(self, SS).f(a, b)
    checkSupSub("a = procCall(SupCls(self).f(a, b))"):
      a = super().f(a, b)
    checkSupSub("a = procCall(SupCls(self).f(procCall(SupCls(self).m()), b))"):
      a = super().f(super().m(), b)
    checkSupSub("echo(1)"): echo(1)

    # NOTE: the following is not supported, so left unchanged
    checkSupSub("super()"): super()
    checkSupSub("super().a"): super().a

  result = n.copy()
  var i = start
  while i<result.len:
    discard replaceSuperCall(result, defSupCls)
    if result[i].len != 0:
      result[i] = recReplaceSuperCall(result[i], defSupCls, 0)
    i.inc

func remove1[T](s: var seq[T], x: T) =
  ## remove the first `x` found in `s`
  var idx: int
  block foundIdx:
    for i, v in s:
      if v == x:
        idx = i
        break foundIdx
    return
  s.delete idx

proc tryPreClsBltinDecorater(mparser: var PyAsgnRewriter,
  args: var seq[NimNode], procType: var NimNodeKind,
  pragmas: var seq[NimNode],
): bool =
  #[
    @staticmethod
    def f(...)   ->   def f(_`gensym: typedesc[Cls],...)

    @classmethod
    def f(cls...) ->   def f(cls: typedesc[Cls]...)
  ]#
  template withType(procTyp) =
    procType = procTyp
  if mparser.decorators.len == 0:
    withType(nnkMethodDef)
    return false

  template curClass: NimNode =
    if mparser.classes.len == 0:
      error "TypeError: invalid context. not in class", decor.name
    mparser.classes[^1]
   
  let decor = mparser.decorators.pop()
  template retFalse(procType=nnkMethodDef) =
    withType(procType)
    mparser.decorators.add decor  # add back
    return false
  template purgeBase =
    if mparser.decorators.len != 0:
      # NIM-BUG:
      #[
```Nim
type
  O = object
  Func = proc (t: typedesc[O]): int

func as_is(f: Func): Func = return f 

let f = block:
  proc f(t: typedesc[O]): int = return 3
  as_is(f)
```
will error as below.

if change `as_is(f)` in `let f = block:...` to `f`,
then you will find it compile but `O.f()` gives `0` instead of `3`
]#
      warning "There may be a error like: " & 
        "`Error: cannot instantiate: '_`gensymXXX:type'`"
    pragmas.remove1 ident"base"
  template clsType: NimNode =
    nnkBracketExpr.newTree(ident"typedesc", curClass())
  
  case $decor.name
  of "staticmethod":
    purgeBase()
    args.insert(newIdentDefs(ident"_", clsType), 1)
  of "classmethod":
    purgeBase()
    args[1][1] = clsType
  else:
    retFalse()
  withType(nnkProcDef)
  return true

template mkPragma(pragmas: seq[NimNode]): NimNode =
  if pragmas.len == 0: emptyn
  else: nnkPragma.newNimNode.add pragmas

proc classImpl*(obj, body: NimNode): NimNode = 
  ##[ minic Python's `class`.

support `def` for method with nested `def/class` supported
and `super(...).method`

## *NOTE*:
### Method Overwrite 
Now the implement assume each `def` in each child class
overwrite parent class's `def`, which is surely not always true,

What's more, it will be false in some less-noted cases:
```Nim
class O:
  def f(self): return 1
class O1(O):
  def f(self): return 1.0
```
The above code will cause `Warning: use {.base.} for base methods; baseless methods are deprecated [UseBase]`

as the rettype of previous one is int, while the latter is float,
thus no override and no dynamic dispatch is performed.

### `super` function
Now support `super([self[,SubCls]]).f([arg,...])`

However, only support the one usage above.

That's, neither `a=super()` nor `super().a` is supported

For the precious one, as now `super` is implemented via Nim's `procCall`,
it's not easy to bind `super()`(aka. a `SupCls` instance) to a variable.

For the latter one, as Nim doesn't allow override `SupCls`'s attr (lead to a compile-error),
so if wantting the attr inherited from SupCls, just write it as-is (e.g. `self.a`)
(Technologically, it can be implemented via `std/macros` `owner`)
]##
  # TODO: support Python3.12's `class O[T: SubCls]:`
  # We accept "class Shape:" "class Shape():" or  "Class Shape(object):"
  var
    classId = obj
    supCls = ident"RootObj"
    supClsNode = nnkOfInherit.newTree supCls
    defPragmas = @[ident"base"]
    
  if obj.kind != nnkIdent:  #  class O([SupCls])
    classId = obj[0]
    expectKind obj, nnkCall
    let supLen = obj.len - 1
    if supLen == 1:   #  class O(SupCls)
      supCls = obj[1]
      if supCls.kind != nnkObjectTy: # not `class O(object)`
        supClsNode = nnkOfInherit.newTree supCls
        defPragmas.remove1 ident"base"
    elif supLen > 1:
      error "multi-inhert is not allowed in Nim, " &
        "i.e. only one super class is expected, got " & $supLen
  
  let className = $classId
  
  result = newStmtList()
  var typDefLs = nnkRecList.newTree()
  template addAttr(name; typ=emptyn, defVal=emptyn) =
    typDefLs.add nnkIdentDefs.newTree(name, typ, defVal)
  var defs = newStmtList()
  var parser = newPyAsgnRewriter()
  for def in body:
    var pragmas = defPragmas  # will be set as empty if `isConstruct` or not base
    case def.kind
    of nnkCall: # attr define, e.g. a: int / a: int = 1
      let tup = parseDeclWithType(def)
      addAttr tup.name, tup.typ, tup.val
    of nnkAsgn:  #  a = 1
      addAttr def[0], emptyn, def[1]
    of nnkCommand:  # TODO: support async
      #  def a(b, c=1).
      # Other stuff than defines: comments, etc
      if not def[0].eqIdent "def":
        result.add def
        continue
      let define = def[1]
      let tup = parseSignature(define, ident"auto")
      var procName = tup.name
      let isConstructor = procName.eqIdent "init"
      if isConstructor:
        procName = newIdentNode("new" & className)
        pragmas = @[]
      # First argument is the return type of the procedure
      var args = tup.params
      # push a new stack frame
      parser.push()
      # Statements which will occur before proc body
      var beforeBody = newStmtList()
      if isConstructor:
        expectIdent args[1][0], "self"
        args.delete 1
        args[0] = classId
        template construct(): untyped {.dirty.} = 
          var self: type(result)
          new(self)
        beforeBody.add getAst(construct())
      else:
        if args.len > 1 and args[1][0].eqIdent "self":
          args[1][1] = classId
      # Function body
      parser.classes.add classId
      var docNode: NimNode
      var parsedbody = recReplaceSuperCall(parser.parsePyBodyWithDoc(def[2], docNode), supCls)
      # If we're generating a constructor proc - we need to return self
      # after we've created it
      if isConstructor:
        parsedbody.add nnkReturnStmt.newTree ident"self"
      # Add statement which will occur before function body
      beforeBody.add parsedBody
      if docNode.len != 0:
        beforeBody.insert(0, docNode)
      parser.pop()

      # Finally create a procedure and add it to result!
      var procType: NimNodeKind
      discard parser.tryPreClsBltinDecorater(
        args, procType, pragmas=pragmas
      )
      if isConstructor: procType = nnkProcDef
      let nDef = parser.consumeDecorator(
          newProc(procName, args, beforeBody, 
            procType, pragmas=pragmas.mkPragma)
        )
      defs.add nDef

    of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
      result.add newCommentStmtNode $def
    of nnkPrefix:
      if not parser.tryHandleDecorator def:
        result.add def
    else:
      result.add def  # AS-IS
  let ty = nnkRefTy.newTree nnkObjectTy.newTree(emptyn, supClsNode, typDefLs)
  let typDef = nnkTypeSection.newTree nnkTypeDef.newTree(classId, emptyn, ty)
  result.add quote do:
      when not declared `classId`:
        `typDef`
  result.add defs
  discard parser.classes.pop()
  # Echo generated code
  # echo result.toStrLit