
const sep = '.'
template asVersion*(major, minor: int): string =
  bind sep
  $major & sep & $minor
template asVersion*(major, minor, patch: int): string =
  bind sep
  $major & sep & $minor & sep & $patch
func asVersion*(v: (int, int)): string = asVersion(v[0], v[1])
func asVersion*(v: (int, int, int)): string = asVersion(v[0], v[1], v[2])

import ./versionInfo
export versionInfo

const
  Version* = asVersion(Major, Minor, Patch)
template exportSincePy*(major, minor: int, sym: typed) =
  bind PyMajor, PyMinor
  when (PyMajor, PyMinor) >= (major, minor):
    export sym

import std/macros
proc newCallFrom(sym, params: NimNode): NimNode =
  result = newCall(sym)
  for i in 1..<params.len:
    result.add params[i][0]

proc templWrapExportSincePyImpl(major, minor: int, sym: NimNode): NimNode =
  let emptyn = newEmptyNode()
  result = newNimNode nnkTemplateDef
  let
    impl = sym.getImpl()
    params = impl[3]
  var nparams = params.copyNimTree
  nparams[0] = bindSym"untyped"
  result.add(
    postfix(sym, "*"), emptyn, # term rewrite
    impl[2], nparams,
    emptyn, emptyn, # pragma, preversed
    newStmtList sym.newCallFrom params
  )

macro templWrapExportSincePy*(major, minor: static int, sym: typed) =
  ## generate `template sym*(...): untyped = sym(...)`
  templWrapExportSincePyImpl(major, minor, sym)

when defined(nimdoc):
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
  func addDocImpl(major, minor: int; def: NimNode): NimNode =
    addDocImpl(asVersion(major, minor).descSince, def)
  macro pysince*(major, minor: static int, def) =
    if def.kind == nnkStmtList:
      result = def
    else:
      result = addDocImpl(major, minor, def)

  proc genWrapCall(sym: NimNode): NimNode =
    result = sym.getImpl()         
    var call = sym.newCallFrom result.params
    case result.kind
    of nnkIteratorDef:
      call = quote do:
        for i in `call`: yield i
    of nnkMacroDef, nnkTemplateDef:
      var nres = newNimNode nnkTemplateDef
      nres.add postfix(ident result[0].strVal, "*") # get rid of
      #    Error: cannot use symbol of kind 'macro' as a 'template
      for i in 1..<result.len-1:  # skip body
        nres.add result[i]
      nres.add newEmptyNode()
      result = nres
    else: discard
    result.body = newStmtList call

  macro wrapExportSincePy*(major, minor: static int, sym: typed) =
    if sym.typeKind == ntyProc:  # includes template, macro
      let def = sym.genWrapCall()
      result = addDocImpl(major, minor, def)
    else:
      result = newCall(bindSym"exportSincePy", major.newLit, minor.newLit, sym)

else:
  template pysince*(major, minor: int, def){.dirty.} =
    bind PyMajor, PyMinor
    when (PyMajor, PyMinor) >= (major, minor):
      def
  template wrapExportSincePy*(major, minor: int, sym: typed) =
    bind exportSincePy
    exportSincePy(major, minor, sym)

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
