import std/macros

macro class*(obj, body: untyped): untyped = 
  runnableExamples:
    class O:
      "doc"
      a: int
      b = 2
      c: int = 1
      def f(self): return self.b
    let o = O()
    assert o.f() == 2
  # We accept "class Shape:" and "Class Shape(object):"
  let
    classId = if obj.kind == nnkIdent: obj else: obj[0]
    className = $classId
  
  result = newStmtList()
  let EN = newEmptyNode()
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
      if firstBody[0].kind == nnkTripleStrLit:
        firstBody[0] = newCommentStmtNode($firstBody[0])
      # If we're generating a constructor proc - we need to return self
      # after we've created it
      if isConstructor:
        firstBody.add parseExpr("return self")
      # Add statement which will occur before function body
      beforeBody.add firstBody
      # Finally create a procedure and add it to result!
      defs.add newProc(procName, args, beforeBody, nnkProcDef)
    of nnkStrLit, nnkRStrLit:
      result.add newCommentStmtNode $def
    else:
      discard
  let ty =  nnkRefTy.newTree nnkObjectTy.newTree(EN, EN, typDefLs)
  let typDef = nnkTypeSection.newTree nnkTypeDef.newTree(classId, EN, ty)
  result.add typDef
  result.add defs
  # Echo generated code
  # echo result.toStrLit
