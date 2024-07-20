
const sep = '.'
template asVersion*(v: (int, int)): string = asVersion(v[0], v[1])
template asVersion*(v: (int, int, int)): string = asVersion(v[0], v[1], v[2])
template asVersion*(major, minor: int): string =
  $major & sep & $minor
template asVersion*(major, minor, patch: int): string =
  $major & sep & $minor & sep & $patch

const
  Major* = 0
  Minor* = 9
  Patch* = 1
  Version* = asVersion(Major, Minor, Patch)

  ReleaseLevel* = "alpha"
  Serial* = 0

  PyMajor*{.intdefine.} = 3
  PyMinor*{.intdefine.} = 13
  PyPatch*{.intdefine.} = 0
  PyReleaseLevel* = "final"
  PySerial* = 0

when defined(nimdoc):
  import std/macros
  func addDocImpl(doc: string; def: NimNode): NimNode =
    result = def
    let docN = newCommentStmtNode doc
    case def.kind
    of RoutineNodes:
      result.body.insert(0, docN)
    else:
      error "not impl for node kind: " & $def.kind, def
      ## XXX: I even don't know how to add
      ##   as diagnosis tools like dumpTree just omit doc node of non-proc node
  template descSince(ver: string): string =
    " .. admonition:: since Python " & ver & "\n\n"
  macro pysince*(major, minor: static int, def) =
    result = addDocImpl(asVersion(major, minor).descSince, def)

else:
  template pysince*(major, minor: int, def){.dirty.} =
    when (PyMajor, PyMinor) >= (major, minor):
      def
