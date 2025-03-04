
import std/macros

when not defined(js):
  from std/os import parentDir, `/../`

const
  wuDirPart = "inWordUtils"

const dunder_file = currentSourcePath()
when defined(js):
  from std/strutils import rfind
  func restrict_parentDir(s: string): string {.compileTime.}=
    var idx = s.rfind '/'
    if idx == -1: idx = s.rfind '\\' 
    assert idx != -1, "unreachable: not abs path from currentSourcePath()"
    debugEcho  s[0..<idx]
    s[0..<idx]
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    let sourceDir = dunder_file.restrict_parentDir
    sourceDir & "/../" & lastPart
  ## XXX: when JS and nimvm, parentDir and `/../` cannot work
else:
  func inSourceParentDir(lastPart: string): string{.compileTime.} =
    dunder_file.parentDir /../ lastPart
# NOTE: inSourceParentDir impl is dup in tlib.nim

const wu_Dir = wuDirPart.inSourceParentDir

macro wu_import*(moduleOrfromExpr) =
  ## words utils import
  # possible to add support for varargs, but no need
  let
    modPre = newLit wu_Dir
    slash = ident"/"
  template pre(module): NimNode =
    nnkInfix.newTree(slash, modPre, module)
  if moduleOrfromExpr.len == 0:
    result = nnkImportStmt.newTree pre moduleOrfromExpr
  else:
    let fromExpr = moduleOrfromExpr
    expectKind fromExpr, nnkInfix
    expectIdent fromExpr[0], "from"
    let
      sym = fromExpr[1]
      module = pre fromExpr[2]
    result = nnkFromStmt.newTree(module, sym)
