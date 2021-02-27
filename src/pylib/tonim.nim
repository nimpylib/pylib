import std/macros

proc genProc(item: NimNode): NimNode =
  # a(b, c=1)
  let define = item[1]
  var procName = define[0]
  # First argument is the return type of the procedure
  var args = @[newIdentNode("auto")]
  # Statements which will occur before proc body
  var beforeBody = newStmtList()
  # Loop over all arguments expect procedure name
  for i in 1..<define.len:
    # Argument name
    let arg = item[1][i]
    # argument with default value
    if arg.kind == nnkExprEqExpr:
      args.add newIdentDefs(arg[0], newEmptyNode(), arg[1])
      continue
    # Just add argument: auto
    args.add newIdentDefs(arg, ident("auto"), newEmptyNode())
  # Function body
  var firstBody = item[2]
  # Python special "doc" comment
  if firstBody[0].kind == nnkTripleStrLit:
    firstBody[0] = newCommentStmtNode($firstBody[0])
  # If we're generating a constructor proc - we need to return self
  # after we've created it
  # Add statement which will occur before function body
  beforeBody.add firstBody
  # Finally create a procedure and add it to result!
  return newProc(procName, args, beforeBody, nnkProcDef)

macro tonim*(body: untyped): untyped =
  #echo treerepr body
  result = newStmtList()
  for i in 0 ..< body.len:
    result.add body[i]
  # sequence of variables which were already initialized
  # so we don't need to redefine them again
  var assigned = newSeq[string]()
  for i in 0 .. body.len - 1:
    let item = body[i]
    case item.kind
    of nnkCommand:
      # Transform def function definition to Nim
      if $item[0] == "def":
        result[i] = genProc(item)
    of nnkAsgn:
      # variable assignment
      let (varName, varValue) = (item[0], item[1])
      if $varName in assigned:
        # skip initialized var
        continue
      assigned.add $varName
      result[i] = newVarStmt(varName, varValue)
    else: discard


#[
import ../pylib

tonim:
  def add(x, y):
    return x + y

  def subtract(x, y):
    return x - y

  def multiply(x, y):
    return x * y

  def divide(x, y):
    return x / y

  def default_arg(x, y = 5):
    return "hello" * y

  my_list = ["apples", "bananas"]
  print(my_list)

  # Python Program to calculate the square root

  # Note: change this value for a different result
  num = 8

  # To take the input from the user
  #num = float(input('Enter a number: '))

  num_sqrt = num ** 0.5
  print(num_sqrt)

  print add(5, 3)
  print add(5.0, 3.0)
  print subtract(6, 3)
  print multiply(5, 7)
  print divide(35, 7)
  print default_arg(0)

]#