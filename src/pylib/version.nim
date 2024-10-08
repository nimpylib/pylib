
const sep = '.'
template asVersion*(major, minor: int): string =
  bind sep
  $major & sep & $minor
template asVersion*(major, minor, patch: int): string =
  bind sep
  $major & sep & $minor & sep & $patch
func asVersion*(v: (int, int)): string = asVersion(v[0], v[1])
func asVersion*(v: (int, int, int)): string = asVersion(v[0], v[1], v[2])

const
  Major* = 0
  Minor* = 9
  Patch* = 3
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
  func preappendDoc(body: NimNode, doc: string) =
    let first = body[0]
    if first.kind == nnkCommentStmt:
        body[0] = newCommentStmtNode(doc & first.strVal)
    else:
        body.insert(0, newCommentStmtNode doc)
  func addDocImpl(doc: string; def: NimNode): NimNode =
    result = def
    case def.kind
    of RoutineNodes:
      preappendDoc result.body, doc
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
