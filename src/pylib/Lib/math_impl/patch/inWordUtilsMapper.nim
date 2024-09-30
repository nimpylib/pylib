
import std/macros

from std/os import parentDir, `/../`

const Dir = currentSourcePath().parentDir

macro wu_import*(moduleOrfromExpr) =
  ## words utils import
  # possible to add support for varargs, but no need
  let
    modPre = newLit Dir/../"inWordUtils"
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
