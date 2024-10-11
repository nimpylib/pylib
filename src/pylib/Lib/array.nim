## array
## 
## .. hint:: considering unicode array is deprecated since Python3.3,
##   and will be removed in Python3.16,
##   it's not implemented
##
## .. hint:: since python3.13, 'w' (Py_UCS4) array is introduced.
##   here we use Rune in std/unicode as its item type.

import ../version
import ../builtins/list

pysince(3,13):
  import std/unicode
  type Py_UCS4* = Rune  ## inner
  import ../pystring/strimpl
  from ../pyerrors/simperr import TypeError
  from ../builtins/reprImpl import pyreprImpl

import ../pybytes/bytesimpl
import ../pybytearray
export bytesimpl

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

func len*[T](arr: PyArray[T]): int = PyList[T](arr).len

# XXX: if use borrow: `Error: borrow with generic parameter is not supported`
func `@`*[T](arr: PyArray[T]): seq[T]{.inline.} = @(PyList[T](arr))

template itemsize*[T](arr: PyArray[T]): int = sizeof(T)

func newPyArray*[T](): PyArray[T] = PyArray[T] list[T]()
template newPyArray*[T](x): PyArray[T] =
  ## unlike `array`_, when `x` is a literal, type conversion is always needed.
  runnableExamples:
    discard newPyArray[cint]([1.cint, 2])
    # or write: array('i', [1, 2])
  bind list
  PyArray[T] list[T](x)

func fromlist*[T](arr: var PyArray[T], ls: PyList[T]) =
  arr.extend ls

func tolist*[T](arr: PyArray[T]): PyList[T] = PyList[T] arr
func tolist*[T](arr: var PyArray[T]): var PyList[T] = PyList[T] arr

template genCmp(op){.dirty.} =
  func op*[A, B](arr: PyArray[A], other: PyArray[B]): bool{.inline.} =
    list_decl.op(PyList[A](arr), PyList[B](other))
  #[
XXX: CPython's returns NotImplement for other mixin cmp, but nimpylib doesn't
go as CPython does, checking NotImplement and then raiseing TypeError,
so we just leave it not defined
  ]#

#[ CPython has special banches for same-type array: ```
Fast path:
  arrays with same types can have their buffers compared directly
```

That's because Python is dyn-typed whereas C is static-typed and lacks generics.
In Nim, it's no need to write such a banch on hand thanks to generics.
]#

genCmp `==`
genCmp `<=`
genCmp `<`

# ISO-C declare `sizeof(char)` is always 1, but not necessarily 8-bit.
when declared(cuchar):
  # cuchar is deprecated long before, may it be removed?
  {.push warning[deprecated]: off.}
  static: assert cuchar.high.uint8 == uint8.high
else:
  type cuchar*{.importc:"unsigned char".} = char  ## unsigned char

type SomeChar* = char|cschar|cuchar  ## In C, `char`, `unsigned char`, `signed char`
                                     ## are three distinct types,
                                     ## that's, `char` is either signed or unsigned,
                                     ## which is implementation-dependent,
                                     ## unlike other integer types,
                                     ## e.g. int is alias of `signed int`
when declared(cuchar): {.pop.}

static: assert char is cchar

func frombytes*[C: SomeChar](arr: var PyArray[C], buffer: BytesLike) =
  ## append byte from `buffer` to `arr`
  let alen = arr.len
  arr.setLen alen + buffer.len
  var i = alen
  for c in buffer.chars:
    arr[i] = C(c)
    i.inc

func tobytes*(arr: PyArray[SomeChar]): PyBytes = bytes @arr

template getAddr(x): ptr =
  when NimMajor == 1: x.unsafeAddr
  else: x.addr

func getPtr*[T](arr: var PyArray[T]; i: Natural|Natural): ptr T =
  ## EXT.
  ## unstable.
  PyList[T](arr).getPtr i

func frombytes*[T: not SomeChar](arr: var PyArray[T], buffer: BytesLike) =
  ## append byte from `buffer` to `arr`
  runnableExamples:
    when sizeof(cshort) == 2:
      var h = array('h', [1, 2])
      h.frombytes(bytes("\x05\x00"))
      when cpuEndian == littleEndian:
        assert h[2] == 5
      else:
        assert h[2] == 1280

  let bLen = buffer.len
  if bLen mod arr.itemsize != 0:
    raise newException(ValueError, "bytes length not a multiple of item size")
  let aLen = arr.len
  let aMoreLen = bLen div arr.itemsize
  arr.setLen aLen + aMoreLen
  for i in 0..<aMoreLen:
    copyMem(arr.getPtr aLen+i, buffer.getCharPtr(i*arr.itemsize), arr.itemsize)

func tobytes*[T: not SomeChar](arr: PyArray[T]): PyBytes =
  let
    aLen = arr.len
    bLen = aLen * arr.itemsize
  var ba = bytearray bLen
  for i in 0..<aLen:
    copyMem(ba.getCharPtr(i * arr.itemsize), arr.getPtr i, arr.itemsize)
  bytes ba

func fromfile*[T](arr: var PyArray[T], f: File, n: int) =
  ## Currrently only for Nim's `File`
  for _ in 1..n:
    var item: T
    f.readBuffer(item.addr, arr.itemsize)
    arr.append item

func tofile*[T](arr: var PyArray[T], f: File) =
  ## Currrently only for Nim's `File`
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
  pysince(3, 13):
    result['w'] = "Py_UCS4"

func initSizeTable(): Table[string, int]{.compiletime.} =
  result = initTable[string, int] TypeTableSize
  result["cschar"] = sizeof cchar
  template genImpl(typS, typ) =
    result[ typS ] = sizeof typ
  template genU(typ) =
    let cbase = astToStr(typ)
    genImpl cbase, typ
  template genS(typ) =
    let
      cbase = astToStr(typ)
      base = cbase[1..^1]
      ubase = "cu" & base
    genImpl cbase, typ
    genImpl ubase, typ
  genS cchar
  genS cshort
  genS cint
  genS clong
  genS clonglong

  genU cfloat
  genU cdouble
  pysince(3, 13):
    genU Py_UCS4
const SizeTable = initSizeTable()


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


template strImplBody[T](arr: PyArray[T], arrToStr) =
  result = "array('"
  result.add arr.typecode
  result.add '\''
  if arr.len != 0:
    result.add ", "
    result.add arrToStr arr
  result.add ')'

pysince(3, 13):
  func tounicode*(arr: PyArray[Py_UCS4]): PyStr{.inline.} =
    ## .. note:: as PyArray here is static-typed,
    ##   unlike CPython's, no ValueError will be raised
    unicode.`$` @arr
  func `$`*(arr: PyArray[Py_UCS4]): string{.inline.} =
    template repr_tounicode(arr): string = pyreprImpl arr.tounicode()
    strImplBody arr, repr_tounicode

func `$`*[T](arr: PyArray[T]): string{.inline.} =
  template normArrToStr(a): string = $PyList[T](arr)
  strImplBody arr, normArrToStr

# no need to perform any quote, as there're only integers,
# so repr can just the same as `__str__`
func repr*[T](arr: PyArray[T]): string = $arr ## alias for `$arr`

pysince(3,13):
  ## XXX: the `extend` is used by `array(c, ls)`,
  ##  And Py_UCS4-array's extend is not generic,
  ## so it must be placed before `array` proc
  static: assert Py_UCS4 is Rune
  #static: assert compiles(array('w', "1"))
  func extend*(self: var PyArray[Py_UCS4], s: PyStr)

proc arrayTypeParse(typecode: char, typeStr: string): NimNode =
  result = newCall(
    nnkBracketExpr.newTree(
      bindSym"newPyArray",
      ident typeStr
    )
  )

proc arrayTypeParse(typecode: char): NimNode =
  arrayTypeParse typecode, getType typecode

macro array*(typecode: static[char]): PyArray =
  runnableExamples:
    var a = array('i')
    assert a.typecode == 'i'
    assert len(a) == 0
    a.append(3)
    assert a.len == 1 and a[0] == 3
  arrayTypeParse typecode

proc parseArrInitLit(lit: NimNode, typeStr: string): NimNode =
  if lit.kind != nnkBracket: return lit
  let typeId = ident typeStr
  result = nnkBracket.newTree:
    newCall(typeId, lit[0])
  for i in 1..<lit.len:
    result.add lit[i]

func isByteLike(node: NimNode): bool =
  node == bindSym"PyBytes" or node == bindSym"PyByteArray"

macro array*(typecode: static[char], initializer: typed): PyArray =
  ## bytes or bytearray, a Unicode string,
  ## or iterable over elements of the appropriate type.
  ## 
  ## `initializer` can be a bracket stmt, no need to manually add type convert,
  ## see examples
  runnableExamples:
    assert array('i', [1, 2])[1] == c_int(2)
    assert array('b', bytes("123"))[2] == c_schar('3')

  let
    typeStr = getType typecode
    baseInitCall = typecode.arrayTypeParse(typeStr)
  let
    typ = initializer.getTypeInst
    # not use getType, which returns concrete impl
  if typ.typeKind == ntyArray:
    result = baseInitCall.add initializer.parseArrInitLit(typeStr)
    return
  result = newStmtList()
  let res = genSym(nskVar, "arrayNewRes")
  result.add newVarStmt(
    res,
    baseInitCall
  )
  let meth = if typ.isByteLike:
    bindSym"frombytes"
  else:
    bindSym"extend"
  result.add newCall(
    newDotExpr(
      res,
      meth
    ), initializer
  )
  result.add res

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
  ## array.byteswap
  ## 
  ## Currently only compilable for `c_*` types,
  ## a.k.a. not for Nim's `int*`, e.g. `int16`
  ## 
  ## .. hint:: trial of using this method on `PyArray[int*]` may lead to
  ##  compile-error of C compiler.
  runnableExamples:
    when sizeof(cshort) == 2:
      var arr = array('h', [1, 2])
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
  let body = newStmtList().add(
    nnkBindStmt.newTree(sym),
    wrappedCall)
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

# len is defined above
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

pysince(3,13):
  wrapMMeth(clear)
  func `[]=`*(self: var PyArray[Py_UCS4], i: int, v: char){.inline.} =
    runnableExamples:
      from std/unicode import Rune
      var a = array('w', "123")
      a[0] = Rune(65)
      a[1] = '3'
    self[i] = Rune v
  func asRune(s: string): Rune =
    when not defined(danger):
      let le = s.runeLen
      if le != 1:
        raise newException(TypeError, "array item must be a unicode character, " &
                     "not a string of length " & $le)
    s.runeAt 0
  func `[]=`*(self: var PyArray[Py_UCS4], i: int, v: string){.inline.} =
    self[i] = v.asRune

  func w_getitem(self: var PyArray[Py_UCS4], i: int): Py_UCS4{.inline.} = self[i]
  func `[]=`*(self: var PyArray[Py_UCS4], i: int): PyStr{.inline.} = str self.w_getitem i
  func fromunicode*(self: var PyArray[Py_UCS4], s: PyStr){.inline.} =
    ## .. note:: as PyArray here is static-typed,
    ##   unlike CPython's, no ValueError will be raised
    for r in s.runes:
      self.append r
  func extend*(self: var PyArray[Py_UCS4], s: PyStr) = self.fromunicode s
  func append*(self: var PyArray[Py_UCS4], s: PyStr){.inline.} =
    self.append s.asRune
