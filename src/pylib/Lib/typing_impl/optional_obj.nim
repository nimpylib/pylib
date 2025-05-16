import std/options
import ../../noneType
type
  OptionalObj*[T] = distinct Option[T]

using self: OptionalObj
template wrap(meth){.dirty.} =
  proc meth*[T](self: OptionalObj[T]): bool = Option[T](self).meth
wrap isSome
wrap isNone

proc `is`*(self; _: NoneType): bool = self.isNone
proc `==`*(self; _: NoneType): bool = self.isNone

converter unsafeGet*[T](self: OptionalObj[T]): T =
  assert self.isSome, self.repr & " cannot be None"
  Option[T](self).unsafeGet


converter unsafeToNone*[T](self: OptionalObj[T]): NoneType =
  assert self.isNone

proc newOptionalObj*[T](x: T): OptionalObj[T] = OptionalObj[T] some(x)
proc newOptionalObj*[T](): OptionalObj[T] = OptionalObj[T] none[T]()

template expOptObjCvt* =
  export optional_obj except newOptionalObj, isSome, isNone, OptionalObj
