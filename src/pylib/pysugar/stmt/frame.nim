## Stack Frame

type
  Decorator* = ref object
    name*: NimNode
    case called*: bool
    of true: args*: seq[NimNode]
    of false: discard
  PyAsgnFrame* = ref object
    parent: PyAsgnFrame
    locals: seq[string]
    decorators: seq[Decorator]  # for Py's `@decorator` before `def`
  PyAsgnRewriter* = object
    supportGenerics*: bool
    frame: PyAsgnFrame
    classes*: seq[NimNode]  ## class type, 
                          ## empty if outside a `class` definition
    globals*: seq[string]

proc newPyAsgnFrame*(): PyAsgnFrame =
  new result
  result.parent = nil

proc newPyAsgnRewriter*(supportGenerics=false): PyAsgnRewriter =
  result.frame = newPyAsgnFrame()
  result.supportGenerics = supportGenerics

using mparser: var PyAsgnRewriter

proc decorators*(mparser): var seq[Decorator] =
  mparser.frame.decorators  

proc push*(mparser) =
  ## push stack frame
  let nFrame = newPyAsgnFrame()
  #nFrame.decorators = mparser.frame.decorators
  # when met a decorator, a new frame is not pushed yet
  nFrame.parent = mparser.frame
  mparser.frame = nFrame
proc pop*(mparser) =
  ## pop stack frame
  let oldStack = mparser.frame
  mparser.frame = oldStack.parent
proc add*(mparser; ident: string) =
  ## add ident to current stack frame.
  mparser.frame.locals.add ident
proc contains*(mparser; ident: string): bool =
  ## check if ident is in current stack frame.
  ident in mparser.frame.locals or
    ident in mparser.globals
proc onceDeclInFrames*(ident: string, mparser;): bool =
  ## lookup `ident` throughout all frames
  ## but globals.
  var frame = mparser.frame
  while frame != nil:
    if ident in frame.locals:
      return true
    frame = frame.parent
proc nonlocalContains*(mparser; ident: string): bool =
  mparser.frame.parent.locals.contains ident
proc nonlocalAdd*(mparser; ident: string) =
  mparser.frame.parent.locals.add ident
