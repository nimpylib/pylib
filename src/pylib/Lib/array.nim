
import ../builtins/list as listlib
export listlib

import ../pybytes/bytesimpl
import ../pybytearray

import std/[macros, strutils, tables]
import std/endians

type
  PyArray*[T] = distinct PyList[T]

iterator mitems*[T](arr: var PyArray[T]): var T =
  ## EXT.
  runnableExamples:
    var arr = array('i', [1, 2])
    for i in arr.mitems:
      i *= 2
    assert arr == array('i', [2, 4])
  for i in PyList[T](arr).mitems(): yield i

func setLen*[T](arr: var PyArray[T], n: int) = PyList[T](arr).setLen n  # EXT.

template itemsize*[T](arr: PyArray[T]): int = sizeof(T)

func newPyArray*[T](): PyArray[T] = PyArray[T] list[T]()
template newPyArray*[T](x): PyArray[T] = PyArray[T] list[T](x)

func fromlist*[T](arr: var PyArray[T], ls: PyList[T]) =
  arr.extend ls

func tolist*[T](arr: PyArray[T]): PyList[T] = PyList[T] arr
func tolist*[T](arr: var PyArray[T]): var PyList[T] = PyList[T] arr

func `==`*[T](arr, other: PyArray[T]): bool = PyList[T](arr) == PyList[T](other)

func `$`*[T](arr: PyArray[T]): string =
  result = "array('"
  result.add arr.typecode
  result.add '\''
  if arr.len != 0:
    result.add ", "
    result.add $PyList[T](arr)
  result.add ')'

func repr*[T](arr: PyArray[T]): string = $arr  # no need to perform any quote

# ISO-C declare `sizeof(char)` is always 1, but not necessarily 8-bit.
when declared(cuchar):
  {.push warning[deprecated]: off.}
  static: assert cuchar.high.uint8 == uint8.high
else:
  type cuchar*{.importc:"unsigned char".} = char
type cschar*{.importc:"signed char".} = char

type SomeChar* = char|cschar|cuchar
when declared(cuchar): {.pop.}

static: assert char is cchar

func frombytes*(arr: var PyArray[SomeChar], buffer: BytesLike) =
  let alen = arr.len
  arr.setLen alen + buffer.len
  var i = alen
  for c in buffer.chars:
    arr[i] = c
    i.inc

func tobytes*(arr: PyArray[SomeChar]): PyBytes = bytes @arr

func fromfile*[T](arr: var PyArray[T], f: File, n: int) =
  for _ in 1..n:
    var item: T
    f.readBuffer(item.addr, arr.itemsize)
    arr.append item

func tofile*[T](arr: var PyArray[T], f: File) =
  for x in arr:
    f.writeBuffer(x.addr, arr.itemsize)

const typecodes* = "bBuhHiIlLqQfd"

# a table that will be used to map, e.g. 'h' to cshort, 'H' to cushort
const OriginTable = {
  # char is treated specially, as `char` may be either signed or unsigned
  'h': "short",
  'i': "int",
  'l': "long",
  'q': "longlong",
  # float and double are signed only
}

const TypeTableSize = 2*OriginTable.len + 2
func initTypeTable(): Table[char, string]{.compiletime.} =
  result = initTable[char, string] TypeTableSize
  result['b'] = "cschar"; result['B'] = "cuchar"
  result['f'] = "cfloat"; result['d'] = "cdouble"
  for (k, v) in OriginTable:
    result[k] = 'c' & v
    result[ k.toUpperAscii ] = "cu" & v

const CodeTypeMap = initTypeTable()

func getType(c: char): string{.inline.} = CodeTypeMap[c]

template genWithTypeCode(mapper#[: Callable[[NimNode, char], NimNode]#): NimNode =
  var result = newStmtList()
  for k, v in CodeTypeMap.pairs():
    let typ = ident v
    result.add mapper(typ, k)
  result

macro genTypeCodeGetters =
  template mapper(typ, k): NimNode{.dirty.} =
    # Currently, `char`/`cuchar`, `culong`/`clong` are some types considered as alias.
    # who knows if this will change in the future, so just use `when not compiles`
    let res = newLit k
    quote do:
      when not compiles(newPyArray[`typ`]().typecode):
        template typecode*(_: PyArray[`typ`]): char = `res`
  genWithTypeCode mapper

genTypeCodeGetters()

func buffer_info*[T](arr: PyArray[T]): tuple[
    address: int, length: int] = # maybe the address shall be pointer or ptr T?
  result.address = cast[typeof result.address](arr[0].addr)
  result.length = arr.len

proc arrayTypeParse(typecode: char, typeStr: string): NimNode =
  result = newCall(
    nnkBracketExpr.newTree(
      bindSym"newPyArray",
      ident typeStr
    )
  )

proc arrayTypeParse(typecode: char): NimNode =
  arrayTypeParse typecode, getType typecode

macro array*(typecode: static[char]): PyArray = arrayTypeParse typecode

proc parseArrInitLit(lit: NimNode, typeStr: string): NimNode =
  if lit.kind != nnkBracket: return lit
  let typeId = ident typeStr
  result = nnkBracket.newTree:
    newCall(typeId, lit[0])
  for i in 1..<lit.len:
    result.add lit[i]

macro array*(typecode: static[char], initializer: typed): PyArray =
  ## bytes or bytearray, a Unicode string, or iterable over elements of the appropriate type.
  runnableExamples:
    var a = array('i')
    assert a.typecode == 'i'
    assert a.len == 0
    a.append(3)
    assert a.len == 1 and a[0] == 3
  let typeStr = getType typecode
  typecode.arrayTypeParse(typeStr).add initializer.parseArrInitLit(typeStr)



func initSizeTable(): Table[string, int] =
  result = initTable[string, int] TypeTableSize
  result["cschar"] = sizeof cchar
  template genS(typ) =
    let
      cbase = astToStr(typ)
      base = cbase[1..^1]
      ubase = "cu" & base
    result[ cbase ] = sizeof typ
    result[ ubase ] = sizeof typ
  genS cchar
  genS cshort
  genS cint
  genS clong
  genS clonglong
  genS cfloat
  genS cdouble
const SizeTable = initSizeTable()

template getBitSize(typeStr: string): int =
  let res = SizeTable.getOrDefault(typeStr, -1) * BitPerByte
  assert res > 0, "unknown type " & typeStr
  res

template getBitSizeStr(typ): string = $getBitSize($typ)

const BitPerByte = 8

# calls e.g. swapEndian64
template swapProcForT(T: NimNode): NimNode =
  ident "swapEndian" & getBitSizeStr(T)

template swapByte[C: SomeChar](_: C) = discard  # do nothing

when NimMajor == 1:
  template getAddr(x): untyped = x.unsafeAddr
else:
  template getAddr(x): untyped = x.addr

macro genSwapByte() =
  template mapper(typ; _): NimNode{.dirty.} =
    let procId = swapProcForT typ
    quote do:
      when not compiles( (var temp:`typ`; temp.swapByte()) ):
        template swapByte(x: var `typ`) =
          var tmp: typeof(x)
          `procId`(tmp.getAddr, x.getAddr)
          x = tmp
  genWithTypeCode mapper
genSwapByte()

func byteswap*[T](arr: var PyArray[T]) =
  runnableExamples:
    var arr = newPyArray[cshort]([1.cshort, 2])
    arr.byteswap()
    assert arr[0] == 256, $arr[0]  # int from \x01\x00
    assert arr[1] == 512, $arr[1]
  for x in arr.mitems():
    swapByte x

# `tolist(var PyArray): PyList` doesn't be called impilitly when array's self-modifiaction
# methods are called

template EmptyN: NimNode = newEmptyNode()

proc wrapMethImpl(sym: NimNode; paramColonExprs: openArray[NimNode], resType=EmptyN): NimNode =
  ## wrap mutable method
  # template sym*[T](arr: PyArray[T], ...<arg: typ>) = sym(arr.tolist, arg...)
  let emptyn = EmptyN
  let self = ident"arr"
  let genericType = ident"T"
  let selfType = nnkBracketExpr.newTree(ident"PyArray", genericType)
  # as this generates a template, no need to mark param as var
  #newIdentDefs(self, nnkVarTy.newTree(ident"PyArray"))
  var procParams = @[
      resType,
      newIdentDefs(self, selfType)
  ]
  var wrappedCall = newCall:
    self.newDotExpr(bindSym"tolist").newCall().newDotExpr(sym)
  for colonExpr in paramColonExprs:
    expectKind colonExpr, nnkExprColonExpr
    let (param, typ) = (colonExpr[0], colonExpr[1])
    procParams.add newIdentDefs(param, typ)
    wrappedCall.add param
  let body = wrappedCall
  let
    pragmas = newEmptyNode()
    generics = nnkGenericParams.newTree(
      newIdentDefs(
        genericType, emptyn, emptyn
      )
    )
  result = nnkTemplateDef.newTree(
    postfix(sym, "*"),
    emptyn,  # rewrite pattern
    generics,
    newNimNode(nnkFormalParams).add(procParams),
    pragmas,
    emptyn,  # reserved
    body)

macro wrapMeth(sym: untyped; resType; paramColonExprs: varargs[untyped]) =
  var ls: seq[NimNode]
  for p in paramColonExprs: ls.add p
  wrapMethImpl(sym, ls, resType)
macro wrapMMeth(sym: untyped; paramColonExprs: varargs[untyped]) =
  # as wrapMeth generates a template,
  # so just use it even though `self` is in fact a var param.
  var ls: seq[NimNode]
  for p in paramColonExprs: ls.add p
  wrapMethImpl(sym, ls)


wrapMeth(len, int)
wrapMeth(`[]`, T, i: int)
wrapMeth(contains, bool, x: T)
wrapMeth(items, untyped)

wrapMMeth(`[]=`, i: int, val: T)
wrapMMeth(delitem, n: int)
wrapMMeth(`+=`, x: untyped)
wrapMMeth(`*=`, n: int)


wrapMMeth(append, x: T)
wrapMMeth(extend, x: untyped)
wrapMMeth(insert, x: T)
wrapMMeth(remove, x: T)
wrapMMeth(pop)
wrapMMeth(pop, i: int)
wrapMMeth(reverse)

