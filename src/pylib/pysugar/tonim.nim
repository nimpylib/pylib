import std/macros

type PyAsgnRewriter* = object
  assigned: seq[string]

proc newPyAsgnRewriter*(): PyAsgnRewriter =
  discard
proc clear*(parser: var PyAsgnRewriter) = parser.assigned.setLen 0

proc genDeclAndRaise*(self: var PyAsgnRewriter; body: NimNode): NimNode =
  ## rewrite `raise` and assignment from Python to Nim
  result = newStmtList()
  # sequence of variables which were already initialized
  # so we don't need to redefine them again
  
  for item in body:
    case item.kind
    of nnkVarSection, nnkLetSection, nnkConstSection:
      # support mixin `let/var/const`
      for defs in item:
        mparser.add $item[0]
      result.add item
    of nnkAsgn:
      # variable assignment
      let (varName, varValue) = (item[0], item[1])
      if $varName in self.assigned:
        result.add item
      else:
        self.assigned.add $varName
        result.add newVarStmt(varName, varValue)
    of nnkCommand:
      let preCmd = $item[0]
      if preCmd == "global" or preCmd == "nonlocal":
        let varName = item[1]
        self.assigned.add $varName
      else:
        var cmd = newNimNode nnkCommand
        for i in item:
          cmd.add:
            if i.kind == nnkStmtList:
              mparser.genNimFromPython i
            else: i
        result.add cmd
    of nnkRaiseStmt:
      var rewriteRes = item
      var msg = newLit ""
      block rewriteRaise:
        proc rewriteWith(err: NimNode) =
          let nExc = newCall("newException", err, msg)
          # User may define some routinues that are used in `raise`,
          rewriteRes = quote do:
            when compiles(`nExc`):
              raise `nExc`
            else:
              `rewriteRes`
          
        let raiseCont = item[0]
        case raiseCont.kind
        of nnkCall:
          # raise ErrType[(...)]
          let err = raiseCont[0]
          let contLen = raiseCont.len
          if contLen > 2:
            # cannot be python-like `raise`
            break rewriteRaise
          if contLen == 2:
            # raise ErrType(msg)
            msg = raiseCont[1]
          rewriteWith err
        of nnkIdent:  # raise XxError
          let err = raiseCont
          rewriteWith err  # in case `raise <a Template>`
        else:
        #of nnkEmpty: # leave `raise` as-is
          break rewriteRaise
      result.add rewriteRes
    else:
      result.add:
        if item.len == 0: item
        else: self.genDeclAndRaise item


template genNimFromPython*(body): untyped =
  ## may do more later
  var parser = newPyAsgnRewriter()
  parser.genDeclAndRaise(body)

macro tonim*(body): untyped =
  runnableExamples:
    var GLOBAL = 1
    tonim:
      num = 8
      global GLOBAL
      GLOBAL = 3
      doAssertRaises ValueError: raise ValueError
      doAssertRaises ValueError: raise ValueError()
      doAssertRaises ValueError: raise ValueError("msg")
      doAssertRaises ValueError:
        # Nim-favor is remained.
        raise newException(ValueError,"msg")
    assert GLOBAL == 3
  result = genNimFromPython(body)

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