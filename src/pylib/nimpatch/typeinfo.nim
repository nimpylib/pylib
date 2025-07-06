## `std/typeinfo` cannot work on weirdTarget,
##  due to lack of mGetTypeInfo (`system.getTypeInfo` cannot work)
## 
## Currently we only re-impl what we need.
import ./utils

import std/typeinfo
addPatch(NimVersionTuple, defined(js) or defined(nimscript)):
  export AnyKind
  type
    Any* = object
      value: pointer
      kind*: AnyKind

  template genGet(T: typedesc, ak){.dirty.} =
    proc `get T`*(v: Any): T =
      assert v.kind == ak
      (cast[ptr T](v.value))[]
  template genToAnyAndGet(T: typedesc){.dirty.} =
    proc toAny*(x: var T): Any =
      result.kind = `ak T`
      result.value = addr x
    genGet T, `ak T`
  genToAnyAndGet bool
  genToAnyAndGet char
  genToAnyAndGet string
  genToAnyAndGet cstring

  template genBare32(T){.dirty.} =
    genToAnyAndGet T
    genToAnyAndGet `T 32`
  genBare32 float  # as float is alias of float64
  genGet float64, akFloat64
  template genBare3264(T){.dirty.} =
    genBare32 T
    genToAnyAndGet `T 64`
  template genBareTo64(T){.dirty.} =
    genToAnyAndGet `T 8`
    genToAnyAndGet `T 16`
    genBare3264 T
  genBareTo64 int
  genBareTo64 uint

  proc getCapTypeName(t: AnyKind): string = ($t)[2..^1]  ## e.g. get `"Int"` from `akInt`

  import std/macros
  macro genParserOfRange(start, stop: static AnyKind) =
    ## start..stop
    let
      pureTypName = start.getCapTypeName
      typName = "Biggest" & pureTypName
      typId = ident typName
      procName = ident "get" & typName
      vId = ident "v"

    var procBody = newStmtList()

    var caseBody = nnkCaseStmt.newTree newDotExpr(vId, ident"kind")

    for kindIdx in start.ord .. stop.ord:
      let kind = cast[AnyKind](kindIdx)
      caseBody.add nnkOfBranch.newTree(
        newLit kind,
        newCall(typId,
          newDotExpr(vId, ident "get" & kind.getCapTypeName)
        )
      )
    caseBody.add nnkElse.newTree(
      quote do:
        raiseAssert "unreachable"; default `typId`
    )

    procBody.add caseBody
    let expProcName = procName.postfix"*"

    result = quote do:
      proc `expProcName`(`vId`: Any): `typId` = `procBody`

  genParserOfRange akInt, akInt64
  genParserOfRange akUInt, akUInt64
  genParserOfRange akFloat, akFloat64


when not hasBug:
  export typeinfo
