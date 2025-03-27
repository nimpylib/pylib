#
import std/[hashes, tables, strformat]
import ../../pyerrors/simperr

template GenPyEnumInit*(Self, Value: typedesc; sym){.dirty.} =
  bind `[]`
  proc sym*(value: Self): Self = value
  proc sym*(value: Value): Self =
    `Self.names`.withValue value, name:
      return `Self.member_map`[name[]]
    raise newException(ValueError, repr(value) & " is not a valid " & $Self)

template GenPyEnumMeth*(Self; Value: typedesc; genObjMeth = true, genInit = false, nameError = NameError, Str = string){.dirty.} =
  ## XXX: NIM-BUG: as `std/tables` is not working with `bind` once required at compile time,
  ##   `import std/tables` is a must before using this template.
  bind contains, `[]`
  bind hash, Table, Hash, withValue, `[]=`, `$`, items, len, fmt, formatValue
  var `Self.names`{.compileTime.}: Table[Value, string]  ## self._name_
  var `Self.member_map`{.compileTime.}: Table[Str, Self]  ## cls._member_map_
  bind GenPyEnumInit

  using self: Self
  using cls: typedesc[Self]
  proc value*(self): Value{.inline.} = Value(self)

  proc name*(self): Str{.inline.} = `Self.names`[self.value]
  proc `name=`(self; name: Str){.inline.} = `Self.names`[self.value] = name
  proc repr*(self): Str =
    let vr = when compiles(typeof(self).value_repr(self.value)):
      typeof(self).value_repr(self.value)
    else:
      repr(self.value)
    fmt"<{$typeof(self)} {self.name}: {vr}>"

  proc `$`*(self): string =
    fmt"{$typeof(self)}.{self.name}"
  proc hash*(self): Hash = hash(`Self.names`[self.value])
  when genObjMeth:
    proc `==`*(self; other: Self): bool = self.value == other.value
  proc add_member(cls; name: Str, self) =
    if name in `Self.member_map`:
      if `Self.member_map`[name] != self:
        let s = repr(`Self.member_map`[name])
        raise newException(nameError, fmt"{repr(name)} is already bound: {s}")
      return
    # XXX: Python here also need to handle property and class attribute
    `Self.member_map`[name] = self
  proc add_alias*(self; name: Str) = Self.add_member(name, self)
  when genInit:
    GenPyEnumInit(Self, Value, Self)


  # _simple_enum's convert_class's Enum / IntEnum / StrEnum branch
  proc add_member*(enum_class: typedesc[Self]; name: Str, value: Value): Self =
    let member = Self(value)
    `Self.member_map`.withValue name, contained:
      # an alias to an existing member
      contained[].add_alias(name)
      result = contained[]
    do:
      # finish creating member
      member.name = name
      enum_class.add_member(name, member)
      result = member



  proc `[]`*(cls; name: string): Self = `Self.member_map`[name]
  proc len*(cls): int = len `Self.names`
  iterator items*(cls): Self =
    for k in `Self.names`.keys(): yield k

  template contains*(cls; value: Self): bool = true
  proc contains*(cls; value: Value): bool =
    `Self.names`.withValue value, name:
      return name in `Self.member_map`
  
