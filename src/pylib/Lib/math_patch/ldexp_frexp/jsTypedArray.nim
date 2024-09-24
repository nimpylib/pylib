
import std/macros

# {.noInit.} for TypedArray caused compile-error in Nim 2.0.8 (not in 2.1.9)
type
  TypedArray*[T] = object of JsRoot

func buffer*(self: TypedArray): JsRoot{.importjs: "(#).buffer".}

func capName(s: string): string{.compileTime.} =
  char(s[0].int and ord('_')) & s[1..^1]

macro genNewTA(T: typedesc) =
  let
    s = capName(repr(T)) & "Array"
    typeName = newLit s
    sym = ident("new" & s)
  result = quote do:
    func `sym`*(x: auto): TypedArray[`T`]{.importjs: "new " & `typeName` & "(#)".}

#func newTypedArray*[T](x: auto): TypedArray[T]{.importjs: "new " & toArrName($T) & "(#)".}

genNewTA uint8
genNewTA uint16
genNewTA uint32

genNewTA float32
genNewTA float64

func `[]`*[T](x: TypedArray[T], i: cint): T{.importjs: "#[#]".}
func `[]=`*[T](x: TypedArray[T], i: cint, val: T){.importjs: "#[#]=#;".}
