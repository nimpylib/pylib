# TODO: add support for mixin ops between types and then better support `predict` param
import std/macros
import std/typeinfo except isNil

type MemberType = Any

func `$`*(t: MemberType): string =
  case t.kind
  of akInt: result = $t.getInt
  of akInt8: result = $t.getInt8
  of akInt16: result = $t.getInt16
  of akInt32: result = $t.getInt32
  of akInt64: result = $t.getInt64
  of akUInt: result   = $t.getUInt
  of akUInt8: result  = $t.getUInt8
  of akUInt16: result = $t.getUInt16
  of akUInt32: result = $t.getUInt32
  of akUInt64: result = $t.getUInt64

  of akFloat:  result = $t.getFloat
  of akFloat32:  result = $t.getFloat32
  of akFloat64:  result = $t.getFloat64
  of akFloat128:
    doAssert false, "float128 not supported"

  of akString: result =   t.getString
  of akCString: result = $t.getCString
  of akBool:
    result = $t.getBool
  of akChar:
    result = $t.getChar
  of akEnum:
    result = $t.getEnumField
  of akObject, akTuple:
    t.setObjectRuntimeType
    for i in t.fields:
        result.add $i
  of akArray, akSequence:
    for i in 0..<t.len:
        result.add $t[i]
  of akSet:
    for i in t.elements:
        result.add $i
  of akRange:
    result = $t.getInt
  of akRef, akPtr, akProc, akPointer:
    result = repr t.getPointer
  of akNone:
    doAssert false, "akNone"

type
    GetMemberType* = (string, MemberType)  #tuple[name: string, value: MemberType]
    GetMembersType* = seq[GetMemberType]
    GetMembersPredict* = proc(x: MemberType): bool
iterator getmembers*[T](obj: var T): GetMemberType =
  for name, value in obj.fieldPairs:
    yield (name, value.toAny)

iterator getmembers*[T](obj: var T, predict: GetMembersPredict): GetMemberType =
  for name, value in obj.fieldPairs:
    if predict(value):
      yield (name, value.toAny)

template getmembersImpl*[R](obj; predict; initResult): R =
  bind getmembers
  var result: R = initResult()
  for t in obj.getmembers():
    if predict(t[1]):
      result.add(t)
  result

template allTrue*(_): bool = true

template getmembers*(obj): seq =
  bind getmembersImpl, allTrue
  getmembersImpl[GetMembersType](obj, allTrue, newSeq[GetMemberType])

template getmembers*(obj; predict: GetMembersPredict): seq =
  bind getmembersImpl
  getmembersImpl[GetMembersType](obj, predict, newSeq[GetMemberType])


template gen_getmembers_static*(prag): untyped{.dirty.} =
  template getmembers_static*(obj; predict: GetMembersPredict): untyped{.prag.} =
    bind getmembers; getmembers(obj, predict)

  template getmembers_static*(obj): untyped{.prag.} = bind getmembers; getmembers(obj)

gen_getmembers_static dirty   # dirty doesn't affect much

when isMainModule:
  type T = object
    a, b: int
    c: char
  var t: T
  echo t.getmembers()
