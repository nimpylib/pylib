
import std/macros
import ./frame, ./funcSignature, ./decorator, ./types
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

type
  MethKind = enum
    mkNorm
    mkCls
    mkStatic

proc replaceSuperCall(n: var NimNode, defSupCls: NimNode, methKind: MethKind): bool =
  template nret(cond): untyped =
    if not cond:
      return
  nret n.kind == nnkCall
  nret n[0].kind == nnkDotExpr
  let callSup = n[0][0]
  nret callSup.kind == nnkCall
  nret callSup[0].eqIdent "super"

  var cLen = callSup.len
  let supCls =
    if cLen > 2:
      if cLen > 3: error "super([<cls>[, self]]) expected, but got too many args"
      callSup[1]
    else:
      if cLen == 1:
        callSup.add defSupCls
        cLen.inc
      defSupCls

  if methKind == mkCls:
    if cLen == 3:
      expectIdent callSup[2], "cls"
    else:
      callSup.add ident"cls"
      cLen.inc
    n = newDotExpr(supCls, n[0][1]).newCall(callSup[2])
  elif methKind == mkNorm:
    if cLen > 1:
      expectIdent callSup[2], "self"
    n[0][0] = newCall(supCls, ident"self")

    #let meth = n[0][1]
    #let args = n[1..^1]

    n = newCall(ident"procCall", n)

  result = true

template new*[T; R: RootRef](_: typedesc[R], cls: typedesc[T],
    _: varargs[untyped]): typedesc[T] =
  ## py's `object.__new__`
  cls

proc recReplaceSuperCall*(n: NimNode, defSupCls: NimNode, start=0, methKind=mkNorm): NimNode =
  ##[ Recursively maps

### 1.

`super(...).f(...)`
    to `procCall(<SuperClass>(self).f(...))`

The AST map:
```
  Call
    DotExpr
      Call
        Ident "super"
        [<SuperClass>]
        [Ident "self"]
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
      <args>
```

### 2
`super(...).new/init_subclass(...)`
    to `<SuperClass>.new/init_subclass(...)`
]##
  runnableExamples:
    import std/[macros, strutils]
    macro checkSupSub(resStr: static string; b) =
      let res = recReplaceSuperCall(b, ident"SupCls")
      assert resStr == repr(res).strip(), repr(res)
      result = newStmtList()
    checkSupSub("procCall(SupCls(self).f())"):
      super().f()
    checkSupSub("procCall(SS(self).f(a, b))"):
      super(SS, self).f(a, b)
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
    discard replaceSuperCall(result, defSupCls, methKind=methKind)
    if result[i].len != 0:
      result[i] = recReplaceSuperCall(result[i], defSupCls, 0, methKind=methKind)
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

proc rmBase(n: var seq[NimNode]) =
  n.remove1 ident"base"

proc tryPreClsBltinDecorater(mparser: var PyAsgnRewriter,
  args: var seq[NimNode], procType: var NimNodeKind,
  pragmas: var seq[NimNode], methKind: var MethKind
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
    pragmas.rmBase
  template clsType: NimNode =
    nnkBracketExpr.newTree(ident"typedesc", curClass())
  
  if decor.name.len != 0:
    return false
  case $decor.name
  of "staticmethod":
    methKind = mkStatic
    purgeBase()
    args.insert(newIdentDefs(ident"_", clsType), 1)
  of "classmethod":
    methKind = mkCls
    purgeBase()
    args[1][1] = clsType
  else:
    retFalse()
  withType(nnkProcDef)
  return true

template mkPragma(pragmas: openArray[NimNode]): NimNode =
  if pragmas.len == 0: emptyn
  else: nnkPragma.newNimNode.add pragmas

proc newMethAsProc(name, generics: NimNode, params: openArray[NimNode], body: NimNode, procType = nnkProcDef, pragmas: openArray[NimNode]): NimNode =
  let procType = (if procType == nnkMethodDef: nnkProcDef else: procType)
  var pragmas = @pragmas
  pragmas.rmBase
  newProc(name, generics, params, body, procType, pragmas.mkPragma)

proc mkExport(n: NimNode): NimNode = n.postfix"*"

proc newMethProc(topLevel: bool, name, generics: NimNode, params: openArray[NimNode], body: NimNode, procType = nnkProcDef, pragmas: openArray[NimNode]): NimNode =
  if topLevel:
    var pragmas = @pragmas
    pragmas.rmBase
    result = newProc(name.mkExport, generics, params, body, procType, pragmas.mkPragma)
  else:
    result = newMethAsProc(name, generics, params, body, procType, pragmas)
    result.addPragma ident"used"

proc genNewCls(topLevel: bool, classNewProcName, classId, generics: NimNode, initArgs, initPragmas: openArray[NimNode]): NimNode =
  ## returns decl of proc
  var newArgs = @[classId]
  var body = newStmtList()
  let resId = ident"result"
  var callNew = newCall(newDotExpr(classId, ident"new"), newCall("typeof", classId))
  let defInit = initArgs.len > 0
  var callInit: NimNode
  if defInit:
    #var init = newCall(ident"init", resId)
    callInit = newCall(resId.newDotExpr(ident"init"))
    for i in 2..<initArgs.len:  # skip `resType` and `self: Cls`
      let argDef = initArgs[i].copyNimTree  # we cannot use the old, as it's a symbol
      # or there will be a error: positional param was already given as named param
      newArgs.add argDef
      callNew.add argDef[0]
      callInit.add argDef[0]
  body.add newAssignment(resId, nnkObjConstr.newTree(callNew))
  if defInit:
    body.add callInit
  var pragmas = @initPragmas
  pragmas.rmBase
  newMethProc(topLevel, classNewProcName, generics, newArgs, body, pragmas=pragmas)

proc classImpl*(parser: var PySyntaxProcesser; obj, body: NimNode, topLevel = true): NimNode =
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
  # We accept "class Shape:" "class Shape():" or  "Class Shape(object):"
  var
    classId = obj
    supCls = ident"RootObj"
    defPragmas = @[ident"base"]
    generics = emptyn
  template parseGenerics(n: NimNode) =
    if parser.supportGenerics:
      classId = parseGenericParams(generics, n)
    else:
      error "generics support is not opened (pysince 3.12)", n
  var initSubClassArgs = @[emptyn]  # will be `[0]=`
  var supClses: seq[NimNode]
  case obj.kind
  of nnkIdent:
    discard
  of nnkCall:
    #  class O([SupCls])
    if obj[0].kind == nnkBracketExpr:
      parseGenerics obj[0]
    else:
      classId = obj[0]
    for i in 1..<obj.len:
      let arg = obj[i]
      case arg.kind
      of nnkExprEqExpr:
        initSubClassArgs.add arg
      of nnkObjectTy:
        supClses.add ident"RootObj"
      else:
        supClses.add arg
    let supLen = supClses.len
    if supLen > 1:
      error "multi-inhert is not allowed in Nim, " &
        "i.e. only one super class is expected, got " & $supLen
    elif supLen == 1:
      #  class O(SupCls)
      supCls = supClses[0]
    if not supCls.eqIdent"RootObj": # not `class O(object)`
      if not topLevel:
        error "non-topLevel class cannot inherit currently " &
          "(as Nim's method must be top-level)", obj[1]
      defPragmas.rmBase
  of nnkBracketExpr:
    parseGenerics obj
  else:
    error "unexpected class syntax, got: ", obj
  let supClsNode = nnkOfInherit.newTree supCls
  
  let className = $classId
  var
    genericsClassId = classId
    concreteGenericsClassId = classId
  if generics.len != 0:
    genericsClassId = nnkBracketExpr.newTree(classId)
    concreteGenericsClassId = nnkBracketExpr.newTree(classId)

    for i in generics.items():
      # i.kind == nnkIdentDef
      genericsClassId.add i[0]
      concreteGenericsClassId.add(
        if i[2].kind != nnkEmpty: i[2]
        elif i[1].kind != nnkEmpty: i[1]
        else: bindSym"char"  # any is okey.
      )
  initSubClassArgs[0] = newCall(bindSym"typeof", concreteGenericsClassId)
  template exportIfTop(n: NimNode): NimNode =
    if topLevel: n.mkExport
    else:
      nnkPragmaExpr.newTree(n, nnkPragma.newTree ident"used")
  result = newStmtList()
  parser.classes.add classId
  let dunderDirId = ident className & ".dunder.dict.keys()"  # `classId.__dict__.keys()`
  var dunderDirVal = newNimNode(nnkBracket)
  var typDefLs = nnkRecList.newTree()
  template addAttr(name; typ=emptyn, defVal=emptyn) =
    typDefLs.add nnkIdentDefs.newTree(name, typ, defVal)
  var defs = newStmtList()
  var decls = newStmtList()
  template addMeth(def: NimNode) = defs.add def
  #[ return type 'auto' cannot be used in forward declarations
  template addMethWithDecl(def: NimNode) =
    defs.add def
    var decl = def.copyNimNode
    let lastI = def.len - 1
    for i in 0..<lastI:
      decl.add def[i].copyNimTree
    decl.add newEmptyNode()
    decls.add decl
  ]#
  var noNew = true
  var
    initArgs: seq[NimNode]
    initGenerics = newNimNode nnkGenericParams
    initPragmas: seq[NimNode]
  for def in items(body):
    var pragmas = defPragmas  # will be set as empty if `isConstructor` or not base
    case def.kind
    of nnkCall:
      # - attr define, e.g. a: int / a: int = 1
      # - dotted called decorator, e.g. @unittest.skipIf(COND, MSG)
      if def.len == 2 and def[0].kind == nnkIdent:
        let tup = parseDeclWithType(def)
        addAttr tup.name, tup.typ, tup.val
      else:
        parser.pushDecorator extractDottedCalledDecorator def
    of nnkAsgn:  #  a = 1
      addAttr def[0], emptyn, def[1]
    of nnkCommand:  # TODO: support async
      #  def a(b, c=1).
      # Other stuff than defines: comments, etc
      if def[0].eqIdent "class":
        result.add parser.classImpl(def[1], def[2], topLevel=false)
        continue
      elif not def[0].eqIdent "def":
        result.add def
        continue
      let signature = def[1]
      let deftype = ident"auto"
      var generics_cpy = generics.copyNimTree()
      let tup = parser.parseSignatureMayGenerics(generics_cpy, signature, deftype)
      var procName = tup.name
      dunderDirVal.add newLit procName.strVal
      let
        isConstructor = procName.eqIdent "init"
        isNew = procName.eqIdent "new"
      var methKind: MethKind
      if isNew or procName.eqIdent "init_subclass":
        methKind = mkCls
      if isNew:
        noNew = false
        pragmas = @[]
      # First argument is the return type of the procedure
      var args = tup.params
      # push a new stack frame
      parser.push()
      var body = newStmtList()
      template markSelfType =
        args[1][1] = genericsClassId
      template chk1ArgCls =
        if not args[1][0].eqIdent "cls":
          warning "the 1st arg of __new__ is not cls, but " & args[1][0].repr,
            args[1]
        args[1][1] = classId
      if isConstructor:
        if args[0].strVal in ["None", "auto"]:
          args[0] = newEmptyNode()
        expectIdent args[1][0], "self"
        markSelfType
        initArgs = args
      elif methKind == mkCls:
        if isNew:
          args[0] = nnkBracketExpr.newTree(bindSym"typedesc", genericsClassId)
        chk1ArgCls
      elif methKind == mkStatic:
        discard
      else:
        if args.len > 1 and args[1][0].eqIdent "self":
          markSelfType
      # Function body
      var docNode: NimNode
      var parsedbody = recReplaceSuperCall(
        parser.parsePyBodyWithDoc(def[2], docNode), supCls,
        methKind=methKind)
      if docNode.len != 0:
        body.insert(0, docNode)
      # Add statement which will occur before function body
      body.add parsedBody
      parser.pop()

      # Finally create a procedure and add it to result!
      var procType: NimNodeKind
      discard parser.tryPreClsBltinDecorater(
        args, procType, pragmas=pragmas, methKind=methKind
      )
      if methKind != mkNorm:
        procType = nnkProcDef
      elif isConstructor:
        initPragmas = pragmas
        initGenerics = generics_cpy
      let nDef = parser.consumeDecorator(
          newMethProc(topLevel, procName, generics_cpy, args, body, 
            procType, pragmas=pragmas)
        )
      addMeth nDef

    of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
      result.add newCommentStmtNode $def
    of nnkPrefix, nnkDotExpr:
      if not parser.tryHandleDecorator def:
        result.add def
    else:
      result.add def  # AS-IS

  addMeth genNewCls(topLevel, ident("new" & classId.strVal), classId, initGenerics, initArgs, initPragmas)

  let ty = nnkRefTy.newTree nnkObjectTy.newTree(emptyn, supClsNode, typDefLs)
  let typDef = nnkTypeSection.newTree nnkTypeDef.newTree(classId.exportIfTop, generics, ty)
  result.add:
    nnkWhenStmt.newTree(
      nnkElifBranch.newTree(
        prefix(newCall("declaredInScope", classId), "not"),
        newStmtList typDef
      )
    )

  # result.add quote do:
  #     when not declaredInScope `classId`:
  #       `typDef`

  result.add decls
  result.add defs
  
  result.add newConstStmt(
    dunderDirId.exportIfTop, dunderDirVal
  )
  let initSub = newCall("init_subclass").add initSubClassArgs
  result.add nnkWhenStmt.newTree(
    nnkElifBranch.newTree(newCall("compiles", initSub),
      initSub
    )
  )

  discard parser.classes.pop()
  # Echo generated code
  # echo result.toStrLit
