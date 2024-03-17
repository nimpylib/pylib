import std/macros

macro class*(obj, body: untyped): untyped = 
  ##[
*NOTE*: Now the implement assume each `def` in each child class
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

]##
  runnableExamples:
    class O:
      "doc"
      a: int
      b = 2
      c: int = 1
      def f(self): return self.b
    let o = O()
    assert o.f() == 2

    class O1(O):
      a1 = -1
      def f(self): return self.a1
    let o1 = O1()
    assert o1.a == 0
    let oo: O = o1
    assert oo.f() == -1,$oo.f() 

    # err: class OO(O1, O): aaa = 1
  # We accept "class Shape:" "class Shape():" or  "Class Shape(object):"
  let EN = newEmptyNode()
  var
    classId: NimNode = obj
    supClsNode = nnkOfInherit.newTree ident"RootObj"
    pragmas = nnkPragma.newTree ident"base"
  if obj.kind != nnkIdent:  #  class O([SupCls])
    classId = obj[0]
    expectKind obj, nnkCall
    let supLen = obj.len - 1
    if supLen == 1:   #  class O(SupCls)
      supClsNode = nnkOfInherit.newTree obj[1]
      pragmas = EN
    elif supLen > 1:
      error "multi-inhert is not allowed in Nim, " &
        "i.e. only one super class is expected, got " & $supLen
  
  let className = $classId
  
  result = newStmtList()
  var typDefLs = nnkRecList.newTree()
  template addAttr(name; typ=EN, defVal=EN) =
    typDefLs.add nnkIdentDefs.newTree(name, typ, defVal)
  var defs = newStmtList()
  for def in body:
    case def.kind
    of nnkCall: # attr define, e.g. a: int / a: int = 1
      expectLen def, 2
      let
        name = def[0]
        rhs = def[1]
      expectKind rhs, nnkStmtList
      expectLen rhs, 1
      let inner = rhs[0]
      var typ, defVal: NimNode = EN
      if inner.kind == nnkAsgn: #  a: int = 1
        typ = inner[0]
        defVal = inner[1]
      else: #  a: int
        typ = inner
      addAttr name, typ, defVal
    of nnkAsgn:  #  a = 1
      addAttr def[0], EN, def[1]
    of nnkCommand:  #  def a(b, c=1).
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
      # Other stuff than defines: comments, etc
      if not def[0].eqIdent "def":
        result.add def
        continue
      let define = def[1]
      var procName = define[0]
      var isConstructor = false
      if procName.eqIdent "init":
        procName = newIdentNode("new" & className)
        isConstructor = true
      # Procedure return type (as string)
      var typ = if isConstructor: className else: "auto" 
      # First argument is the return type of the procedure
      var args = @[newIdentNode(typ)]
      # Statements which will occur before proc body
      var beforeBody = newStmtList()
      # Loop over all arguments expect procedure name
      for i in 1..<define.len:
        # Argument name
        let arg = def[1][i]
        # argument with default value
        if arg.kind == nnkExprEqExpr:
          args.add newIdentDefs(arg[0], newEmptyNode(), arg[1])
          continue
        # Special self argument
        if arg.eqIdent "self":
          # We need to create an instance of ref object
          # and we don't want to have instance as argument in a constructor
          if isConstructor:
            template construct(): untyped {.dirty.} = 
              var self: type(result)
              new(self)
            beforeBody.add getAst(construct())
            continue
          # We need to add it to procedure arguments
          # like self: Shape
          else:
            let arg = newIdentDefs(newIdentNode("self"), classId, newEmptyNode())
            args.add(arg)
            continue
        # Just add argument: auto
        args.add newIdentDefs(arg, ident("auto"), newEmptyNode())
      # Function body
      var firstBody = def[2]
      # Python special "doc" comment
      if firstBody[0].kind in nnkStrLit..nnkTripleStrLit:
        firstBody[0] = newCommentStmtNode($firstBody[0])
      # If we're generating a constructor proc - we need to return self
      # after we've created it
      if isConstructor:
        firstBody.add parseExpr("return self")
      # Add statement which will occur before function body
      beforeBody.add firstBody
      # Finally create a procedure and add it to result!
      defs.add newProc(procName, args, beforeBody, nnkMethodDef, pragmas=pragmas)
    of nnkStrLit, nnkRStrLit, nnkTripleStrLit:
      result.add newCommentStmtNode $def
    else:
      discard
  let ty = nnkRefTy.newTree nnkObjectTy.newTree(EN, supClsNode, typDefLs)
  let typDef = nnkTypeSection.newTree nnkTypeDef.newTree(classId, EN, ty)
  result.add typDef
  result.add defs
  # Echo generated code
  # echo result.toStrLit
