
import ./typeinfo
import std/macros
from std/strutils import addSep

proc getCapTypeName(t: AnyKind): string = ($t)[2..^1] ## e.g. get `"Int"` from `akInt`


{.pragma: dollar, noSideEffect, gcSafe.}

proc `$`*(x: Any): string{.dollar.}

const anyDollarNotSupportCollectionType{.booldefine.} = false
const anyDollarSupportCollectionType{.booldefine.} = not anyDollarNotSupportCollectionType

template `x=>`(xbody): untyped{.dirty.} =
  proc (x: Any): string{.dollar.} = xbody

template `@`(p: proc(x: Any): string): untyped = `x=>` p(x)

template len(c: char): int = 1
template joinImpl(iterVar; itor: iterable, left, right; sToAdd){.dirty.} =
  mixin left, right
  result.add left
  for iterVar in itor:
    result.addSep(startLen = left.len)
    result.add sToAdd
  result.add right

when anyDollarSupportCollectionType:
  template join(p: typed, left, right): untyped{.dirty.} = `x=>` do:
    joinImpl i, p(x), left, right:
      $i

  template join(left, right): untyped{.dirty.} = `x=>` do:
    joinImpl i, 0..<x.len, left, right:
      $x[i]

  proc nilOrPrefixed(x: Any, pre: string): string =
    if x.isNil: "nil" else: pre & $x[]

proc dollarFields(x: Any): string =
  ## join(fields, '(', ')')`x=>` do:
  joinImpl t, x.fields, '(', ')':
    t.name & ": " & $t.any

proc withFields_ab(x: Any, a, b: var Any): bool =
  var cnt = 0
  for (k, v) in x.fields:
    if cnt == 0 and k == "a":
      a = v
      inc cnt
    elif cnt == 1 and k == "b":
      b = v
      inc cnt
    else:
      return false
  return cnt == 2

proc dollarTuple(x: Any): string =
  var a, b: Any
  if #[x.baseTypeKind == akNone and
    #[XXX: object with no base will be of akTuple over akObject, ref
    ref https://github.com/nim-lang/Nim/issues/25029
    So I don't know whether object with no base's baseTypeKind is akNone or not
    ]#
  ]# x.withFields_ab(a, b):
    # is of `slice`
    $a & " .. " & $b
  else:
    x.dollarFields
    #[XXX: TODO: fields fails to yield name correctly for namedtuple
    ref https://github.com/nim-lang/Nim/issues/25028
    ]#
  
  #[
  So in short, the must bug of `$` for `Any` is:

    - both non-named and namedtuple will be returned in form of `(Field0: ...)`

  before either of the two bugs mentioned above gets fixed
  ]#

proc unreachable{.noReturn.} =
  raiseAssert "unreachable"
proc unreachableDollar(_: Any): string =
  unreachable()

proc getFloat128(x: Any): string = unreachable()

const
  akGetableAndDollarable = {
    akBool, akChar,
    akString, akCString,
    akInt..akUInt64
  }

  akDollarMapSupported = {
     akNone: unreachableDollar
    ,akEnum: @getEnumField
    ,akObject: dollarFields
    ,akTuple: dollarTuple
    ,akProc, akPointer: `x=>` repr getPointer(x)
  }

when anyDollarSupportCollectionType:
  const akDollarMap = {
     akArray: join('[', ']')
    ,akSequence: join("@[", ']')
    ,akSet: join(elements, '{', '}')
    ,akRange: `x=>` $skipRange(x)
    ,akPtr: `x=>` x.nilOrPrefixed"ptr "  # the same as repr(ptr T)
    ,akRef: `x=>` x.nilOrPrefixed"ref "  # NOT the same as repr(ref T),
    # which returns `type(attr: val[,...])` but we cannot get typename
  }

macro dollarImpl(x: Any) =
  result = nnkCaseStmt.newTree newDotExpr(x, ident"kind")

  for ak in akGetableAndDollarable:
    result.add nnkOfBranch.newTree(
      newLit ak,
      newAssignment(
        ident"result",
        newCall("get" & ak.getCapTypeName, x).prefix"$"
      )
    )
  template addFromMap(m){.dirty.} =
    for pair in m:
      let call = pair[1]
      result.add nnkOfBranch.newTree(
        newLit pair[0],
        quote do: result = `call`(`x`)
      )
  addFromMap akDollarMapSupported
  when anyDollarSupportCollectionType:
    addFromMap akDollarMap
  else:
    result.add nnkElse.newTree(
      quote do:
        unreachable()
    )

proc `$`*(x: Any): string{.dollar.} =
  dollarImpl(x)    # which returns `type(attr: val[,...])` but we cannot get typename

when isMainModule:
  proc str[T](x: T): string =
    var i = x
    var a = i.toAny
    #echo x, ' ', $a, ' ', a.kind, ' ', $a.baseTypeKind
    $a
  import std/unittest
  proc chk[T](x: T) =
    check x.str == $x
  chk 1
  chk 3.14
  chk 'c'
  chk 101i8

  chk littleEndian  # enum

  type O = object
    Field0: int
    Field1: float
  let obj = O(Field0: 3, Field1: 2.5) 
  chk obj

  type AA = object of RootObj
  chk AA()

  when anyDollarSupportCollectionType:
    chk [3, 4]
    chk @[3, 4]
    chk {5, 7}

    #chk (name: 1)

    chk 1..2


    var x: range[1..2] = 2
    chk x

