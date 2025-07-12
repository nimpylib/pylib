## formatValue for bool, char, cstring and typeinfo.Any

import std/strformat
import ../nimpatch/typeinfo
import ../nimpatch/anydollar

import std/macros
template genFormatValue(T){.dirty.} =
  proc formatValue*(result: var string, x: T, spec: string) =
    result.formatValue($x, spec)

genFormatValue bool
genFormatValue char
genFormatValue cstring

proc getCapTypeName(t: AnyKind): string = ($t)[2..^1]  ## e.g. get `"Int"` from `akInt`

proc formatValue(s, x, spec: NimNode): NimNode =
  newCall(bindSym"formatValue", s, x, spec)

const
  akGetableAndFormatValueable = {
    akBool, akChar,
    akString, akCString,
    akInt..akFloat64,
    akUInt..akUInt64,
  }

macro formatValueImpl(s: string, x: Any, spec: string) =
  # ref `anydollar.dollarImpl`_ (private)
  result = nnkCaseStmt.newTree newDotExpr(x, ident"kind")

  for ak in akGetableAndFormatValueable:
    result.add nnkOfBranch.newTree(
      newLit ak,
      formatValue(
        s, newCall("get" & ak.getCapTypeName, x), spec
      )
    )
  
  result.add nnkElse.newTree(
    formatValue(s, newCall(bindSym"$", x), spec)  
  )

proc formatValue*(result: var string, x: Any, spec: string) =
  formatValueImpl(result, x, spec)

when isMainModule:
  var x = 3
  var a = x.toAny
  var s = "^"
  s.formatValue a, ""
  echo s

