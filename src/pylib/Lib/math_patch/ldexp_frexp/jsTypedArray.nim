
import std/macros

type
  TypedArray*[T]{.noInit.} = object of JsRoot
    buffer*: JsRoot

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

genNewTA uint32
genNewTA uint16

genNewTA float64
genNewTA float32

func `[]`*[T](x: TypedArray[T], i: cint): T{.importjs: "#[#]".}
func `[]=`*[T](x: TypedArray[T], i: cint, val: T){.importjs: "#[#]=#;".}
