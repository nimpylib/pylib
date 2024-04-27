## Stack Frame

type
  PyAsgnFrame* = ref object
    parent: PyAsgnFrame
    locals: seq[string]
  PyAsgnRewriter* = object
    frame: PyAsgnFrame
    globals*: seq[string]

proc newPyAsgnFrame*(): PyAsgnFrame =
  new result
  result.parent = nil

proc newPyAsgnRewriter*(): PyAsgnRewriter =
  result.frame = newPyAsgnFrame()

using mparser: var PyAsgnRewriter

proc push*(mparser) =
  ## push stack frame
  let nFrame = newPyAsgnFrame()
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
