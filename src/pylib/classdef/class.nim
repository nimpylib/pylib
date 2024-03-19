import std/macros
import ./pydef

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

macro class*(obj, body: untyped): untyped = 
  ##[ minic Python's `class`.

support `def` for method
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
]##
  runnableExamples:
    class O:
      "doc"
      a: int
      b = 2
      c: int = 1
      def f(self): return self.b
    assert O().f() == 2
    
    class O1(O):
      a1 = -1
      def f(self): return self.a1
    assert O1().a == 0
    assert O(O1()).f() == -1

    # will error: class OO(O1, O): aaa = 1

    class C:
      def f(self, b: float) -> int: return 1+int(b)
    assert C().f(2) == 3

    class CC(C):
      def f(self, b: float):
        return super().f(b)
    assert CC().f(2) == 3
  
  # We accept "class Shape:" "class Shape():" or  "Class Shape(object):"
  var
    classId = obj
    supCls = ident"RootObj"
    supClsNode = nnkOfInherit.newTree supCls
    pragmas = nnkPragma.newTree ident"base"
    
  if obj.kind != nnkIdent:  #  class O([SupCls])
    classId = obj[0]
    expectKind obj, nnkCall
    let supLen = obj.len - 1
    if supLen == 1:   #  class O(SupCls)
      supCls = obj[1]
      supClsNode = nnkOfInherit.newTree supCls
      pragmas = emptyn
    elif supLen > 1:
      error "multi-inhert is not allowed in Nim, " &
        "i.e. only one super class is expected, got " & $supLen
  
  let className = $classId
  
  result = newStmtList()
  var typDefLs = nnkRecList.newTree()
  template addAttr(name; typ=emptyn, defVal=emptyn) =
    typDefLs.add nnkIdentDefs.newTree(name, typ, defVal)
  var defs = newStmtList()
  for def in body:
    case def.kind
    of nnkCall: # attr define, e.g. a: int / a: int = 1
      let tup = parseDeclWithType(def)
      addAttr tup.name, tup.typ, tup.val
    of nnkAsgn:  #  a = 1
      addAttr def[0], emptyn, def[1]
    of nnkCommand:  #  def a(b, c=1).
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
      # First argument is the return type of the procedure
      var args = tup.params
      # Statements which will occur before proc body
      var beforeBody = newStmtList()
      if args[1][0].eqIdent "self":
        args[1][1] = classId
      if isConstructor:
        expectIdent args[1][0], "self"
        template construct(): untyped {.dirty.} = 
          var self: type(result)
          new(self)
        beforeBody.add getAst(construct())
      # Function body
      var parsedbody = recReplaceSuperCall(parseBody def[2], supCls)
      # If we're generating a constructor proc - we need to return self
      # after we've created it
      if isConstructor:
        parsedbody.add parseExpr("return self")
      # Add statement which will occur before function body
      beforeBody.add parsedBody
      # Finally create a procedure and add it to result!
      defs.add newProc(procName, args, beforeBody, nnkMethodDef, pragmas=pragmas)
    of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
      result.add newCommentStmtNode $def
    else:
      result.add def  # AS-IS
  let ty = nnkRefTy.newTree nnkObjectTy.newTree(emptyn, supClsNode, typDefLs)
  let typDef = nnkTypeSection.newTree nnkTypeDef.newTree(classId, emptyn, ty)
  result.add typDef
  result.add defs
  # Echo generated code
  # echo result.toStrLit
