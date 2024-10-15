
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
    if def.kind == nnkStmtList:
      result = def
    else:
      result = addDocImpl(asVersion(major, minor).descSince, def)

else:
  template pysince*(major, minor: int, def){.dirty.} =
    bind PyMajor, PyMinor
    when (PyMajor, PyMinor) >= (major, minor):
      def

type MajorMinorVersion = tuple[major, minor: int]

template pysince*[R](ver: MajorMinorVersion, defExpr, elseExpr: R): R =
  bind PyMajor, PyMinor
  when (PyMajor, PyMinor) >= ver: defExpr
  else: elseExpr

template toVer(s: MajorMinorVersion): MajorMinorVersion = s
func toVer(s: static float): MajorMinorVersion{.compileTime.} =
  result.major =  int(s)
  let minorF = 10 * (s - float int(s))
  assert minorF.int.float - minorF < 1e10,  # 1e10 is a picked not very strictly.
    "must be in format of major.minor, " & "but got " & $s &
      " debug: delta=" & $(minorF.int.float - minorF)
  result.minor =  int minorF

func pysince*[R](ver: static[float|MajorMinorVersion]; defExpr, elseExpr: R): R{.inline.} =
  bind PyMajor, PyMinor, toVer
  when (PyMajor, PyMinor) >= toVer(ver): defExpr
  else: elseExpr
