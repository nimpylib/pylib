

import std/macros

macro getfile*(obj: typed): string =
  ## in Python this may returns path for .pyc,
  ## but as Nim doesn't generate vm code,
  ## this always returns the actual source file.
  ## Thus the same as `getsourcefile`_
  let info = obj.lineInfoObj
  newLit info.filename

template getsourcefile*(obj: typed): string =
  ## see `getfile`_
  bind getfile
  getfile(obj)


func getlineImpl(obj: NimNode): int = obj.lineInfoObj.line

macro getline*(obj: typed): int = newLit getlineImpl obj

func getsourceImpl(obj: NimNode, res: var string): bool =
  let impl = obj.getImpl()
  if impl.isNil: return
  res.add impl.repr
  result = true

func raiseGetsourceError(obj: NimNode){.noReturn.} =
    let objNode = obj.repr
    error "TypeError: Cannot find source code for '" &
        `objNode` & '\''

template getsourcelinesImpl*(obj: NimNode, splitlines): untyped =
  ## get source code of the object
  ##
  ## the first element is the source code
  ## the second element is the line number of the first line of the source code
  let line = obj.getlineImpl
  var source: string
  if not getsourceImpl(obj, source):
    raiseGetsourceError(obj)
  (splitlines(source), line)

macro getsource*(obj: typed): string =
  ## .. note::
  ##   due to implement limit,
  ##   the result string is not the extract the same as the origin source code,
  ##   but those after some transformations,
  ##   that's something that's allowed to be omitted is added.
  ##   see below for examples
  runnableExamples:
    func f: int =
      ## doc
      1
    static:
      assert getsource(f) == """
func f(): int =
  result =
    ## doc
    1
"""

  var res: string
  if getsourceImpl(obj, res):
    result = newLit res
  else:
    raiseGetsourceError(obj)

func getdocNoDedentImpl*(obj: NimNode): string =
  repr extractDocCommentsAndRunnables obj

