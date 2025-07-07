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
      fields: seq[tuple[name: string, any: Any]]
      baseTypeKind*: AnyKind
  when defined(js):
    {.define: anyDollarNotSupportCollectionType.}
    proc toInt(x: pointer): int = 
      {.emit: "if(`x`_Idx===undefined)`x`_Idx = 0;".}
      cast[int](x)
    proc toPointer(x: int): pointer =
      {.emit: "`result`_Idx = 0;".}
      cast[pointer](x)
  
  else:
    template toInt(x: pointer): int = cast[int](x)
    template toPointer(x: int): pointer = cast[pointer](x)
  template anyWithValue(v: pointer): Any = Any(value: v)

  template genToAny(T: typedesc; ak){.dirty.} =
    proc toAny*(x: var T): Any =
      result.kind = ak
      result.value = addr x
  template genToAny(T: typedesc){.dirty.} =
    genToAny T, `ak T`
  template genGet(T: typedesc, ak){.dirty.} =
    proc `get T`*(v: Any): T =
      assert v.kind == ak
      (cast[ptr T](v.value))[]
  template genToAnyAndGet(T: typedesc){.dirty.} =
    genToAny T
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
  import std/typetraits
  from std/strutils import toLowerAscii
  proc unreachable(){.noReturn.} = raiseAssert "unreachable"
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
        unreachable(); default `typid`
    )

    procBody.add caseBody
    let expProcName = procName.postfix"*"

    result = quote do:
      proc `expProcName`(`vId`: Any): `typId` = `procBody`

  genParserOfRange akInt, akInt64
  genParserOfRange akUInt, akUInt64
  genParserOfRange akFloat, akFloat64

  # == pointer ==
  genToAnyAndGet pointer

  # == enum ==
  proc toAny*[T: enum](x: var T): Any =
    result.kind = akEnum
    result.value = addr x
    result.baseTypeKind = akInt # XXX: FIXME
    for eVal in T:
      result.fields.add ($eVal, anyWithValue(eVal.ord.toPointer))
  proc getEnumField*(x: Any): string =
    assert x.kind == akEnum
    let xVal = cast[ptr BiggestInt](x.value)[]
    for (name, val) in x.fields:
      if cast[int](val.value) == xVal:
        return name


  # == tuple|object ==
  template genToAnyWithFields(TT, ak){.dirty.} =
    proc toAny*[T: TT](x: var T): Any =
      result.kind = ak
      result.value = addr x
      for k, v in fieldPairs(x):
        result.fields.add (k, v.toAny)
  genToAnyWithFields tuple, akTuple
  genToAnyWithFields object, akObject
  iterator fields*(x: Any): tuple[name: string, any: Any] =
    for t in x.fields: yield t


when not hasBug:
  export typeinfo
