## import & export helper
import std/macros

macro impExp*(pre; mods: varargs[untyped]) =
  ## gen: `import ./pre/[...mods]; export ...mods`
  result = newStmtList()
  var imp = newNimNode nnkImportStmt
  var modsList = newNimNode nnkBracket
  for m in mods: modsList.add m

  var impMods = infix(prefix(pre, "./"), "/", modsList)

  imp.add impMods
  result.add imp

  var exp = newNimNode nnkExportStmt
  for m in mods:
    exp.add m
  result.add exp

