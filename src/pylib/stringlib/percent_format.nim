## `__mod__` implementation for `str`, `bytes` or `bytearray`.
## 
from std/strutils import toLowerAscii, isDigit # except `%`  # avoid overload
import std/tables
import std/strformat
import std/typetraits
import ../nimpatch/typeinfo
import ../nimpatch/anydollar

import std/macros

from std/unicode import runeLen, Rune, runeAt

import ../pyerrors/simperr

import ./formatWithSpec


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
      raise newException(TypeError, `errMsgPreId` & v.kind.getTypeName)

  # getBiggestXxx(v) will auto extend value
  procBody.add newCall(procName, vId)

  result = quote do:
    proc `procName`(`vId`: Any, `errMsgPreId`: string): `typId` = `procBody`


genParserOfRange(akInt, akInt64)
genParserOfRange(akFloat, akFloat64)
genParserOfRange(akUInt, akUInt64)

proc err(E: typedesc, msgPre: string){.inline, noReturn.} =
  raise newException(TypeError, msgPre & $E)

proc othersErrImpl(msgPre, def: NimNode): NimNode =
  let emptyn = newEmptyNode()

  result = newStmtList def
  let procType = nnkProcDef
  var nParams = def.params.copyNimTree
  #let E = genSym(nskType, "E")
  var generics = def[2].copyNimTree
  let old1Type = nParams[1][1]
  for i in 0..<generics.len:
    # also works if generics is Empty, when this loop does noop
    if generics[i][0].eqIdent old1Type:
      generics.del i
      if generics.len == 0:
        generics = emptyn
      break
  nParams[1][1] = ident"auto"

  let errDef = procType.newTree(
    def[0], # XXX: NIM-BUG: def.name failed for proc named "`get R`"
    emptyn,
    generics, #nnkGenericParams.newTree(newIdentDefs(E, emptyn)),
    nParams,
    def.pragma,
    emptyn,
    newStmtList newCall(bindSym"err", newCall("typeof", nParams[1][0]), msgPre))
  result.add errDef
macro othersErr(msgPre, def) = othersErrImpl msgPre, def
macro othersErr(def) = othersErrImpl ident"msgPre", def

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
    raise newException(TypeError, cRequiredButNotPre &
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
    raise newException(TypeError, rng256ErrMsg)
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
  {.push overflowCheck: off.}  # we do check by our own.
  when ovfChk:
    if self > (T.high - (T(c) - '0'.ord)) div 10:
      raise newException(ValueError, astToStr(self) & " too big")
  self = self * 10 + (c.ord - '0'.ord)
  {.pop.}


proc raiseUnsupSpec(specifier: char, idx: int) =
  raise newException(ValueError, fmt"unsupported format character: '{specifier}' (0x{specifier.ord:x}) at index {idx - 1}")


#type Getitemable*[K, V] = concept self
#  self[K] is V
# see below

proc Py_FormatEx*[T: untyped
    #[: openArray[T]|Getitemable[string, T]
    where T is Any|string|SomeNumber|char|<string-convertable>
    XXX: not compiles due to NIM-BUG]#
    ](
    format: string, args: T,
    reprCb: proc (x: string): string = repr,
    asciiCb: proc (x: string): string = repr,
    `disallow%b` = true): string =
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
  when declared(newStringOfCap):
    result = newStringOfCap(format.len)
  const dictMode = compiles(args[""])
  when dictMode:
    # It used to be `type InnerVal = string`
    type InnerVal = typeof args[""]
    var darg: InnerVal
    template dict: untyped = args
    template getnextarg(_): InnerVal = darg
  else:
    type InnerVal = typeof args[0]
    var argidx = 0
    let arglen = args.len
    template getnextarg(args): InnerVal =
      ## `getnextarg(args; arglen: int, p_argidx: var int)` but use closure
      ## to mean `getnextarg(args, arglen, argidx)`
      ## so no need for the later 2 arg
      let t_argidx = argidx
      if t_argidx < arglen:
        inc argidx
        args[t_argidx]
      else:
        raise newException(TypeError, "not enough arguments for format string")
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
          raise newException(TypeError, "format requires a mapping")
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

      # Parse width. Example: "%10s" => width=10
      const starWantsInt = "* wants int"
      var width = BiggestInt -1
      if idx < format.len and format[idx] == '*':
        width = getBiggestInt(getnextarg(args), starWantsInt)
        if width < 0:
          flags |= F_LJUST
          width = -width

        inc idx
      elif idx < format.len and format[idx].isDigit:
        width = 0
        while idx < format.len and format[idx].isDigit:
          width.pushDigitChar format[idx]
          inc idx

      # Parse precision. Example: "%.3f" => prec=3
      var prec = BiggestInt -1
      if idx < format.len and format[idx] == '.':
        inc idx
        if idx < format.len and format[idx] == '*':
          prec = getBiggestInt(getnextarg(args), starWantsInt)
          inc idx
        elif idx < format.len and format[idx].isDigit:
          prec = 0
          while idx < format.len and format[idx].isDigit:
            prec.pushDigitChar format[idx]
            inc idx

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
          raise newException(TypeError, "not enough arguments for format string")
        let value = args[argidx]
        inc argidx
      else:
        let value = darg


      var
        spec = StandardFormatSpecifier(
          fill: ' ',
          align: '>',  # `%-format` use right alignment by default for both number and string (unlike f-string)
          sign: '-',
          alternateForm: flags & F_ALT,
          padWithZero: flags & F_ZERO,
          minimumWidth: int width,
          precision: int prec,
          typ: specifier,
        )

      if flags & F_BLANK:
        spec.sign = ' '
      if flags & F_LJUST:
        spec.align = '<'
        spec.padWithZero = false
        #NOTE: left adjusted: `(overrides the '0' conversion if both are given).`
      if flags & F_SIGN:
        spec.sign = '+'

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
        let i = value.getSomeNumberAsBiggestInt &"%{specifier} format: a real number is required, not "
        result.formatValue i, spec
      of 'x', 'X', 'o':
        let i = value.getBiggestInt &"%{specifier} format: an integer is required, not "
        #XXX:
        #[here we cannot mixin `index()` as well as `int()` for `value`, so there's
          no need to check if `int` returns an integer, thus err msg can only be in one form (as used above)
          instead of a string interpolared by "a real number" and type of `value`
          ]#
        result.formatValue i, spec
      of 'u':
        # PY-DIFF: accepting only SomeUnsignedInt over any real number
        let ui = value.getBiggestUInt &"%{specifier} format: an unsigned integer is required, not "
        result.formatValue ui, spec
      of 'f', 'F', 'e', 'E', 'g', 'G':
        let f = value.getSomeNumberAsBiggestFloat "must be real number, not "
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
      raise newException(TypeError, "not all arguments converted during " & (
        if `disallow%b`: "string"
        else: "bytes"
      ) & " formatting")
  {.pop.}  # boundChecks: off

proc allElementsSameType(eleTypes: NimNode, start=0): bool =
  if eleTypes.len <= start: return
  let firstType = eleTypes[start].typeKind
  for i in (start+1)..<eleTypes.len:
    if eleTypes[i].typeKind != firstType:
      return
  return true

template asIs(x): untyped = x
proc tupleToArray(args: NimNode): NimNode =
  ## - tuple[T,...] -> array[I, T]
  ## - otherwise    -> array[I, Any]
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
      mapper = bindSym"toAny"
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

    result.add quote do: `res`[`k`] = `id`.toAny

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

when defined(js):
  # get rid of `Error: 'repr' is a built-in and cannot be used as a first-class procedure`
  proc repr(x: string): string = system.repr(x)

template genPercentAndExport*(S=string,
    reprCb: proc (x: string): string = repr,
    asciiCb: proc (x: string): string = repr,
    disallowPercentb = true){.dirty.} =
  template partial(s; args): untyped =
    bind Py_FormatEx, cvtIfNotString
    cvtIfNotString[S] Py_FormatEx(s, args, reprCb, asciiCb, disallowPercentb)
  template percentFormat(s: S, arg: typed#[Mapping or T]#): S =
    #bind partial
    when compiles(arg[""]):
      partial(s, arg)
    else:
      partial(s, [arg])
  macro percentFormat(s: S, args: tuple): S =
    bind tupleToArray
    bind bindSym, newCall
    newCall bindSym"partial", s, tupleToArray args

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
