## `__mod__` implementation for `str`, `bytes` or `bytearray`.
## 
from std/strutils import toLowerAscii, isDigit # except `%`  # avoid overload
import std/tables
import std/strformat
import std/typetraits
import ../nimpatch/typeinfo
import ../nimpatch/anydollar

import std/macros except `$`, `[]`

from std/unicode import runeLen, Rune, runeAt

import ../pyerrors/simperr
template raise_TypeError(msg) =
  raise newException(TypeError, msg)

import ./formatWithSpec

const staticEval = not defined(pylibDisableStaticPercentFormat)
template onStaticEval(body) =
  bind staticEval
  when staticEval: body

proc getTypeName*(t: AnyKind): string =
  ## e.g. get `"int"` from `akInt`
  ($t)[2..^1]
    .toLowerAscii()  # only for a little better report msg in "* wants "

macro genParserOfRange(start, stop: static AnyKind) =
  ## start..stop
  let
    pureTypName = start.getTypeName
    typName = "Biggest" & pureTypName
    typId = ident typName
    procName = ident "get" & typName
    errMsgPreId = ident"errMsgPre"
    vId = ident "v"

  var procBody = newStmtList quote do:
    if v.kind notin `start` .. `stop`:
      raise_TypeError(`errMsgPreId` & v.kind.getTypeName)

  # getBiggestXxx(v) will auto extend value
  procBody.add newCall(procName, vId)

  result = quote do:
    proc `procName`(`vId`: Any, `errMsgPreId`: string): `typId` = `procBody`


genParserOfRange(akInt, akInt64)
genParserOfRange(akFloat, akFloat64)
genParserOfRange(akUInt, akUInt64)

template err(E: typedesc, msgPre: string) =
  raise_TypeError(msgPre & $E)

proc strValStripAcc(n: NimNode): string =
  if n.kind == nnkAccQuoted:
    for i in n:
      result.add i.strVal
  else:
    result = n.strVal

template borrMacrosGetitem{.dirty.} =
  template `[]`(n: NimNode, i: int): NimNode = macros.`[]`(n, i)

proc othersErrImpl(msgPre, def: NimNode, msgPreIsParam: static bool): NimNode =
  borrMacrosGetitem
  let emptyn = newEmptyNode()

  result = newStmtList def
  let procType = nnkProcDef
  #let E = genSym(nskType, "E")
  let
    old1Type = def.params[1][1]
    def1node = def[0] # XXX: NIM-BUG: def.name failed for proc named "`get R`"
    defName = def1node.strValStripAcc  # assuming def is not exported
  template dupDef(newParams, body: NimNode): NimNode =
    var generics = def[2].copyNimTree
    for i in 0..<generics.len:
      # also works if generics is Empty, when this loop does noop
      if generics[i][0].eqIdent old1Type:
        generics.del i
        if generics.len == 0:
          generics = emptyn
        break

    procType.newTree(ident defName,
      emptyn, generics, #nnkGenericParams.newTree(newIdentDefs(E, emptyn)),
      newParams, def.pragma, emptyn, body
    )

  var nParams: NimNode
  template withNParams(param1type, body) =
    block:
      nParams = def.params.copyNimTree
      nParams[1][1] = param1type
      body

  template errDefBody: NimNode =
    newCall(bindSym"err", newCall("typeof", nParams[1][0]), msgPre)
    
  withNParams ident"auto":
    result.add dupDef(nParams, errDefBody)

  onStaticEval:
    when msgPreIsParam:
      withNParams ident"auto":
        var typ = nnkBracketExpr.newTree(ident"static", nParams[2][1])
        #typ = nnkCurlyExpr.newTree(typ,
        #  ident"lit",
        #  nnkAccQuoted.newTree(ident"const").prefix"~"
        #)
        # static[string]{lit, ~`const`}
        # XXX: a single `lit` not work as expected
        nParams[2][1] = typ
        var def = dupDef(nParams, nnkStaticStmt.newTree errDefBody)
        def.addPragma ident"compileTime"
        result.add def

    let nnn = bindSym"NimNode"
    withNParams nnn:
      nParams[0] = nnn
      let defNameNode = newLit defName
      var call = newCall(bindSym"newCall", quote do:
        `bindSym` `defNameNode`
      )
      call.add nParams[1][0]
      when msgPreIsParam:
        let p = nParams[2][0]
        assert p.eqIdent "msgPre"
        call.add newCall(bindSym"newLit", p)

      result.add dupDef(nParams, call)

macro othersErr(msgPre, def) = othersErrImpl msgPre, def, false
macro othersErr(def) = othersErrImpl ident"msgPre", def, true

template numParse(R){.dirty.} =
  template `get R`(s: SomeNumber|char, msgPre: string): R{.othersErr.} = R s

numParse BiggestInt
numParse BiggestUInt


# == getSomeNumberAsBiggestInt,getSomeNumberAsBiggestFloat ==

template genGetSomeNumber(T){.dirty.} =
  template `getSomeNumberAs T`(v: SomeNumber|char, msgPre: string): T = T v
  proc `getSomeNumberAs T`(v: Any, msgPre: string): T{.othersErr.} =
    case v.kind
    of akFloat .. akFloat64:
      T v.getBiggestFloat msgPre
    of akUInt .. akUInt64:
      T v.getBiggestUInt msgPre
    else:
      T v.getBiggestInt msgPre

genGetSomeNumber BiggestInt
genGetSomeNumber BiggestFloat

const cRequiredButNotPre = "%c requires an int or a unicode character, not "
func chkLen1(slen: int) =
  if slen != 1:
    raise_TypeError(cRequiredButNotPre &
                     "a string of length " & $slen)

const rng256ErrMsg = "%c requires an integer in range(256) or a single byte"

const
  bndChk = compileOption("boundChecks")
  ovfChk = compileOption("overflowChecks")

when bndChk:
  template chkInRange[T: SomeInteger](x: T, hi; body) =
    const unsigned = T is SomeUnsignedInt
    if (
      when unsigned: false
      else: x < 0
    ) or (
      when compiles(hi > high T) and (hi > high T): false
      elif unsigned: BiggestUInt(x) >= hi
      else: BiggestInt(x) >= hi
    ): body
else:
  template chkInRange(x, hi; body) = discard


# == getAsChar,getAsRune ==

template getAsChar(s: char): char = s
proc getAsChar(s: SomeInteger): char =
  s.chkInRange 256:
    raise_TypeError(rng256ErrMsg)
  cast[char](s)

proc getAsChar(s: string|cstring): char =
  s.len.chkLen1
  s[0]

proc getAsChar(v: Any): char{.othersErr(cRequiredButNotPre).} =
  ## byte_converter
  case v.kind
  of akString: getAsChar v.getString
  of akCString: getAsChar v.getCString
  of akChar: v.getChar
  else: getAsChar getBiggestInt(v, rng256ErrMsg)

template raiseOverflowError(msg) =
  raise newException(OverflowDefect, msg)

proc getAsRune(v: Any|string|cstring|openArray[char]|SomeInteger|char): Rune{.
    othersErr(cRequiredButNotPre).} =
  template oa(v): untyped{.used.} = v.toOpenArray(0, v.high)
  when v is openArray[char]:
    v.runeLen.chkLen1
    v.runeAt 0
  elif v is string:
    getAsRune oa v
  elif v is cstring:
    getAsRune(
      when compiles(oa v): oa v
      else: $v  # JS
    )
  elif v is Any:
    case v.kind
    of akChar:
      Rune v.getChar
    of akString:
      let s = v.getString
      getAsRune s
    of akCString:
      let s = v.getCString
      getAsRune s
    else:
      getAsRune v.getBiggestInt cRequiredButNotPre
  else:
    when v is_not char:
      v.chkInRange 0x110000:
        raiseOverflowError "%c arg not in range(0x110000)"
    cast[Rune](v)

#[ FIXME: Error check cannot be handled as following, otherwise `StrLike` like
  `PyBytes` won't work but raise `TypeError` shown as below
template getAsRune[T](v: T): Rune =
  {.error: "TypeError: %c requires an int or a unicode character, not " & $T.}
]#

# == Py_FormatEx ==
onStaticEval:
  template `&=`(result: var NimNode, s: NimNode) =
    result = infix(result, "&", s)

  template formatedValue(v; spec): string =
    var s: string
    s.formatValue v, spec
    s

# NIM-BUG: repr(spec) is (fill: <int>, ..)
#  over StandardFormatSpecifier(fill: char, ...)

onStaticEval:
  proc formatValue(result: var NimNode, x: NimNode, spec: NimNode) =
    result &= newCall(bindSym"formatedValue", x, spec)
  proc formatValue[T](result: var NimNode, x: int, spec: NimNode) =
    result.formatedValue newLit x, spec

  proc add(result: var NimNode, c: char) =
    result &= newLit c

  proc addSubStr(result: var NimNode, s: NimNode, start, stop: int) =
    result &= (quote do: `s`[`start` ..< `stop`])
  proc addSubStr(result: var NimNode, s: string, start, stop: int) =
    result &= newLit s[start ..< stop]

proc addSubStr(self: var string, s: openArray[char], start: int, stop: int) =
  ##[ Add a substring to the string.
     `start..<stop`

   roughly equal to self.add s[start ..< stop]
  ]##
  let rng = start ..< stop
  when declared(copyMem):
    let bLen = self.len
    self.setLen bLen + rng.len
    #for i in rng: self[bLen + i] = s[i]
    copyMem(addr(self[bLen]), addr(s[start]), rng.len)
  else:
    for i in rng:
      self.add s[i]

# ['-', '+', ' ', '#', '0']
const
  F_LJUST = 1 shl 0
  F_SIGN  = 1 shl 1
  F_BLANK = 1 shl 2
  F_ALT   = 1 shl 3
  F_ZERO  = 1 shl 4

template `|=`(f, g: int) =
  ## Bitwise OR for `FormatCode`.
  f = f or g

template `&`(f, g: int): bool =
  ## this should returns int, but here we will only use it in bool context
  bool(f and g)

template pushDigitChar[T: BiggestInt](self: (var T){sym}, c: char) =
  ## assuming c in '0' .. '9'
  {.push overflowChecks: off.}  # we do check by our own.
  when ovfChk:
    if self > (T.high - (T(c) - '0'.ord)) div 10:
      raise newException(ValueError, astToStr(self) & " too big")
  self = self * 10 + (c.ord - '0'.ord)
  {.pop.}

proc parseNonNegBiggestIntAt(idx: var int, s: string): BiggestInt{.inline.} =
  result = 0
  while idx < s.len and s[idx].isDigit:
    result.pushDigitChar s[idx]
    inc idx

proc raiseUnsupSpec(specifier: char, idx: int) =
  raise newException(ValueError, fmt"unsupported format character: '{specifier}' (0x{specifier.ord:x}) at index {idx - 1}")


#type Getitemable*[K, V] = concept self
#  self[K] is V
# see below


template getTypeOfMap(args): untyped =
  when args is NimNode: NimNode
  else: typeof args[""]

proc getLength(d: NimNode): int =
  case d.kind
  of nnkIdent, nnkSym:
    d.getType.len - 1
    #-1  # unknown length
  of nnkTupleConstr, nnkBracket: d.len
  else: error "unknown args of kind: " & $d.kind, d
proc getLength(d: tuple): int = d.tupleLen
template getLength(d): int = d.len

proc callGetItem[T: not NimNode](d: NimNode; ki: T): NimNode =
  nnkBracketExpr.newTree(d, newLit ki)

proc initStandardFormatSpecifier(specifier: char, flags: int, width, prec: SomeInteger
    ): StandardFormatSpecifier =
  var flags = flags
  let
    widthIsNeg = width < 0
    # CPython's check for this is not written here
    #  but you can tell moving here doesn't change functionality
    #  we move here as `initStandardFormatSpecifier` be
    #  running at CT on `onStaticEval`
    width = int(
      if widthIsNeg:
        flags |= F_LJUST
        -width
      else: width
    )
    prec = int prec

  result = StandardFormatSpecifier(
      fill: ' ',
      align: '>',  # `%-format` use right alignment by default for both number and string (unlike f-string)
      sign: '-',
      alternateForm: flags & F_ALT,
      padWithZero: flags & F_ZERO,
      minimumWidth: width,
      precision: prec,
      typ: specifier,
    )

  if flags & F_BLANK:
    result.sign = ' '
  if flags & F_LJUST:
    result.align = '<'
    result.padWithZero = false
    #NOTE: left adjusted: `(overrides the '0' conversion if both are given).`
  if flags & F_SIGN:
    result.sign = '+'


onStaticEval:
  proc initStandardFormatSpecifier(specifier: char, flags: int, width, prec: NimNode#[BiggestInt]#,
      ): NimNode#[StandardFormatSpecifier]# =
    newCall(bindSym"initStandardFormatSpecifier",
      newLit specifier, newLit flags,
      width, prec)

template Py_FormatExImpl[A](result: var (NimNode|string), dictMode: static[bool],
  format: string,
  args: A,
  `disallow%b`: bool
) =
  ## Format a string using a Python-like `%` formatting.
  ## `args` is a sequence of strings to substitute into the format string.
  ## 
  ## if `disallow%b` is true, %c also accept `int` and `Rune`
  ## 
  ## like `PyUnicode_Format` in unicodeobject.c & `_PyBytes_FormatEx` in bytesobject.c
  ## with exceptions:
  ## 
  ## - CPython's `%u` is just the same with `%d` (`%i`, etc), which means accepting negative int and float.
  ##   Therefore, for example, `"%u" % (-1.1,)` just gives `"-1"`,
  ##   which is somewhat felt strange. As of in Nim uint exists, %u refers to any unsigned int.
  bind getTypeOfMap, addSubStr, getLength
  bind raise_TypeError, getBiggestInt, getBiggestFloat,
    getSomeNumberAsBiggestInt, getSomeNumberAsBiggestFloat,
    getAsRune, getAsChar
  bind `|=`, `&`, F_LJUST, F_SIGN, F_BLANK, F_ALT, F_ZERO
  const compileTime = result is NimNode
  const bign1 = BiggestInt -1
  when not compileTime:
    when declared(newStringOfCap):
      result = newStringOfCap(format.len)
    type WidthOrPrec = BiggestInt
    template toWidthOrPrec(x): untyped = x
  else:
    type WidthOrPrec = NimNode
    template toWidthOrPrec(x: BiggestInt): NimNode = newIntLitNode x
    result = newLit ""
    bind callGetItem
    when dictMode:
      proc `[]`(d: NimNode, key: string): NimNode =
        callGetItem(d, key)
    else:
      ## assuming d is args
      var needCallGetItem = args.kind == nnkSym
      proc `[]`(d: NimNode, i: int): NimNode =
        if needCallGetItem: callGetItem(d, i)
        else: macros.`[]`(d, i)

    proc `$`(n: NimNode): NimNode = n.prefix"$"
  const starWantsInt = "* wants int"
  when dictMode:
    # It used to be `type InnerVal = string`
    type InnerVal = getTypeOfMap args
    var darg: InnerVal
    template dict: untyped = args
    proc getBiggestIntFromArgAndNext(): WidthOrPrec =
      raise_TypeError starWantsInt
  else:
    var argidx = 0
    let arglen = getLength(args)
    template getBiggestIntFromArgAndNext(): WidthOrPrec =
      ## `getnextarg(args; arglen: int, p_argidx: var int)` but use closure
      ## to mean `getnextarg(args, arglen, argidx)`
      ## so no need for the later 2 arg
      ##
      ## In addition, you can find getnextarg only used
      ##   before `PyLong_Check` and PyLong_AsInt,PyLong_AsSsize_t,
      ##   so it can be folded, named as `getBiggestIntFromArgAndNext`
      ##
      let t_argidx = argidx
      if t_argidx < arglen:
        inc argidx
        when compileTime:
          args[t_argidx]
        else:
          args[t_argidx].getBiggestInt starWantsInt &
            ", but got "  # PY-DIFF: not have this part, but fine
      else:
        raise_TypeError("not enough arguments for format string")
  {.push boundChecks: off.}
  var idx = 0
  while idx < format.len:
    if format[idx] != '%':
      # Copy non-format characters
      let start = idx
      while idx < format.len and format[idx] != '%':
        inc idx
      result.addSubStr(format, start, idx)
    else:
      # Handle format specifier
      inc idx
      if idx < format.len and format[idx] == '%':  # %% means %
        result.add('%')
        inc idx
        continue

      if idx < format.len and format[idx] == '(':
        # Dictionary mode
        when not dictMode:
          raise_TypeError("format requires a mapping")
        else:
          let start = idx
          inc idx
          var pcount = 1
          while pcount > 0 and idx < format.len:
            inc idx
            if format[idx - 1] == ')':
              dec pcount
            elif format[idx - 1] == '(':
              inc pcount
          if pcount > 0:
            raise newException(ValueError, "incomplete format key")
          let key = format[start + 1 ..< idx - 1]
          darg = dict[key]

      # Parse flags
      var flags = 0
      template pushF(f) =
        flags |= f
        inc idx
      while idx < format.len:
        case format[idx]
        of '-': pushF F_LJUST
        of '+': pushF F_SIGN
        of ' ': pushF F_BLANK
        of '#': pushF F_ALT
        of '0': pushF F_ZERO
        else:
          break

      template getStarFromArgOrTryFromFormatString(): WidthOrPrec =
        if idx < format.len and format[idx] == '*':
          inc idx
          getBiggestIntFromArgAndNext()
        else:
          parseNonNegBiggestIntAt(idx, format).toWidthOrPrec

      # Parse width. Example: "%10s" => width=10
      let width = getStarFromArgOrTryFromFormatString()

      # Parse precision. Example: "%.3f" => prec=3
      var prec = bign1.toWidthOrPrec
      if idx < format.len and format[idx] == '.':
        inc idx
        prec = getStarFromArgOrTryFromFormatString()

      # Skip length spec (type prefix) just as Python does.
      #[ We are able to do so because the type system used here
      is both dynamic and safe. ]#
      if idx < format.len and format[idx] in {'h', 'l', 'L'}:
        inc idx

      # Parse type specifier
      if idx >= format.len:
        raise newException(ValueError, "incomplete format")
      let specifier = format[idx]
      inc idx

      when not dictMode:
        if argidx >= arglen:
          raise_TypeError("not enough arguments for format string")
        let value = args[argidx]
        inc argidx
      else:
        let value = darg

      let spec = initStandardFormatSpecifier(specifier, flags, width, prec)

      template specFmt: string  = '%' & specifier & " format: "
      case specifier
      of 'a':
        let s = asciiCb $value
        result.formatValue s, spec
      # PY-DIFF: Before str, repr, bytes, int, float dynamically invoke objects function attributes,
      #   we cannot dynamically dispatch as Python does.
      of 'r':
        let s = reprCb $value
        result.formatValue s, spec
      of 's', 'b':
        if `disallow%b` and specifier == 'b':
          raiseUnsupSpec(specifier, idx)
        let s = $value
        result.formatValue s, spec
      of 'd', 'i':
        let i = getSomeNumberAsBiggestInt(value, specFmt&"a real number is required, not ")
        result.formatValue i, spec
      of 'x', 'X', 'o':
        let i = value.getBiggestInt specFmt&"an integer is required, not "
        #XXX:
        #[here we cannot mixin `index()` as well as `int()` for `value`, so there's
          no need to check if `int` returns an integer, thus err msg can only be in one form (as used above)
          instead of a string interpolared by "a real number" and type of `value`
          ]#
        result.formatValue i, spec
      of 'u':
        # PY-DIFF: accepting only SomeUnsignedInt over any real number
        let ui = value.getBiggestUInt specFmt&"an unsigned integer is required, not "
        result.formatValue ui, spec
      of 'f', 'F', 'e', 'E', 'g', 'G':
        let f = getSomeNumberAsBiggestFloat(value, "must be real number, not ")
        result.formatValue f, spec
      of 'c':
        if `disallow%b`:
          result.formatValue getAsRune(value), spec
        else:
          result.formatValue getAsChar(value), spec
      else:
        raiseUnsupSpec(specifier, idx)

  when not dictMode:
    if argidx < arglen:
      raise_TypeError("not all arguments converted during " & (
        if `disallow%b`: "string"
        else: "bytes"
      ) & " formatting")
  {.pop.}  # boundChecks: off

proc Py_FormatEx*[T: not NimNode
    #[: openArray[T]|Getitemable[string, T]
    where T is Any|string|SomeNumber|char|<string-convertable>
    XXX: not compiles due to NIM-BUG]#
    ](dictMode: static[bool],
    format: string, args: T,
    reprCb: proc (x: string): string = repr,
    asciiCb: proc (x: string): string = repr,
    `disallow%b` = true
    ): string =
  result.Py_FormatExImpl dictMode, format, args, `disallow%b`

onStaticEval:
  proc Py_FormatEx*(dictMode: static[bool],
      format: string, args: NimNode,
      t_reprCb, t_asciiCb : static[proc (x: string): string],
      `disallow%b` = true
      ): NimNode =
    ## only exported if `pylibDisableStaticPercentFormat` not defined
    proc reprCb(n: NimNode): NimNode = newCall(bindSym"treprCb", n)
    proc asciiCb(n: NimNode): NimNode = newCall(bindSym"tasciiCb", n)
    result.Py_FormatExImpl dictMode, format, args, `disallow%b`

proc allElementsSameType*(eleTypes: NimNode, start=0): bool =
  borrMacrosGetitem
  if eleTypes.len <= start: return
  let firstType = eleTypes[start].typeKind
  for i in (start+1)..<eleTypes.len:
    if eleTypes[i].typeKind != firstType:
      return
  return true

template toAnyId: NimNode = bindSym"toAny"

template asIs(x): untyped = x
proc tupleToArray(args: NimNode): NimNode =
  ## - tuple[T,...] -> array[I, T]
  ## - otherwise    -> array[I, Any]
  borrMacrosGetitem
  result = newStmtList()
  var nargs = args
  let notAtm = args.len != 0
  var arr = newNimNode nnkBracket
  let tupEleTypes = args.getType()  # [0] idx is tuple itself
  let tupLen = tupEleTypes.len - 1

  let canUseNonAnyArr = allElementsSameType(tupEleTypes, 1)
  var mapper: NimNode
  block mkArr:
    # we distinguish several situation to optimize,
    #  preventing unneeded copy (when assigning)
    template arrAddWithEachIdx(i, exp) =
      for i in 0..<tupLen:
        arr.add exp
    if canUseNonAnyArr:
      mapper = bindSym"asIs"
      if notAtm:  # we must ensure it only evaluated once
        if args.kind == nnkTupleConstr:  # is literal
          # e.g. here we directly transform (64,2) to [64, 2]
          arrAddWithEachIdx i, nargs[i]
          break mkArr
        else:  # not literal but may has sideEffect
          nargs = genSym(nskLet, "nargs")
          result.add newLetStmt(nargs, args)
    else:
      mapper = toAnyId
      if notAtm or (
        args.kind == nnkSym and args.symKind != nskVar
        # not `var xxx ...`
      ):
        # NOTE: toAny requires var argument
        nargs = genSym(nskVar, "nargs")
        result.add newVarStmt(nargs, args)
    arrAddWithEachIdx i, quote do:
      `mapper` `nargs`[`i`]
    
  result.add arr

proc toTableWithValueTypeAny(lit: NimNode): NimNode #[Table[string, Any]]# =
  borrMacrosGetitem
  result = newStmtList()  # `toAny` only receive `var`, so we firstly put values on stack

  let res = genSym(nskVar, "res")
  let initLen = newLit lit.len
  result.add newVarStmt(res, quote do: initTable[string, Any](`initLen`))
  for i in lit:
    var kv = i
    while kv.kind == nnkHiddenSubConv and kv[0].kind == nnkEmpty:
      kv = kv[1]
    kv.expectKind {nnkTupleConstr, nnkExprColonExpr}
    let (k, v) = (kv[0], kv[1])
    let id = genSym(nskVar, k.strVal)
    result.add newVarStmt(id, v)

    result.add quote do: `res`[`k`] = `id`.`toAnyId`

  result.add res

#[NOTE:
  
  To support dict literal whose values are of different types,
`%` cannot be overloaded.

If not, dict literal will be resolved,
and Nim will complain it's a invalid Nim expression

So this module only contains one `%` defined
]#
template cvtIfNotString[S](res): S =
  when S is string: res
  else: S res
proc cvtIfNotString[S](res: NimNode): NimNode =
  when S is string: res
  else: newCall(getTypeInst S, res)

when defined(js):
  # get rid of `Error: 'repr' is a built-in and cannot be used as a first-class procedure`
  proc repr(x: string): string = system.repr(x)

template genPercentAndExport*(S=string,
    reprCb: proc (x: string): string = repr,
    asciiCb: proc (x: string): string = repr,
    disallowPercentb = true){.dirty.} =
  bind staticEval, onStaticEval
  template partialBody(dictMode, s, args): untyped{.dirty.} =
    bind Py_FormatEx, cvtIfNotString
    cvtIfNotString[S] Py_FormatEx(dictMode, s, args, reprCb, asciiCb, disallowPercentb)
  template partial(s; args): untyped =
    const dictMode = compiles(args[S""])
    partialBody dictMode, s, args
  proc partial(s: string; args: NimNode, dictMode: static bool): NimNode{.onStaticEval.} =
    partialBody dictMode, s, args

  onStaticEval:
    when S is string:
      template toString(s: S): string = s
    else:
      template toString(s: S): string = string(s)

    type GetitemableOfK[K] = concept self
      self[K]
    template genPercentFormat(T, dictMode){.dirty.} =
      macro percentFormat(s: static S, arg: T): S =
        bind nnkBracket, newTree
        partial(s.toString, (when dictMode: arg else: newTree(nnkBracket, arg)), dictMode)
    genPercentFormat GetitemableOfK[S], true
    genPercentFormat typed, false
  template percentFormat(s: S, arg: typed#[Mapping or T]#): S =
    #bind partial
    partial(s, (when compiles(arg[S""]): arg else: [arg]))
  macro percentFormat(s: S, args: tuple): S =
    bind tupleToArray
    bind bindSym, newCall
    newCall bindSym"partial", s, tupleToArray args
  macro percentFormat(s: static S, args: tuple): S{.onStaticEval.} =
    partial s.toString, args

  macro `%`*(s: S, args: untyped): S =
    bind kind, nnkTableConstr, bindSym, newCall
    bind toTableWithValueTypeAny
    if kind(args) == nnkTableConstr:
      newCall(bindSym"partial", s, toTableWithValueTypeAny(args))
    else:
      newCall(bindSym"percentFormat", s, args)

when isMainModule:
  genPercentAndExport string

  # Test cases
  echo "Hello, %s! Hello %c" % ("World", 86)
  echo "Number: %d" % (42,)
  echo "Hex: %#x" % 255
  echo "Float: %.2f" % (3.14159,)
  echo "Char: %c" % ('A',)
  echo "Dict: %(key)s" % {"key": "value", "k2": 1}
  echo "Multiple: %s, %d" % ("test", 123)
