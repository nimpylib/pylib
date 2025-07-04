## `__mod__` implementation for `str`, `bytes` or `bytearray`.
## 
from std/strutils import toLowerAscii, isDigit # except `%`  # avoid overload
import std/tables
import std/strformat
import std/typetraits
import std/typeinfo

import std/macros

from std/unicode import runeLen, Rune, runeAt

import ../pyerrors/simperr

import ./formatWithSpec

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
    errMsgId = ident"errMsg"

  var procBody = newStmtList quote do:
    if v.kind notin `start` .. `stop`:
      raise newException(TypeError, `errMsgId`)

  var vId = ident "v"
  var caseBody = nnkCaseStmt.newTree newDotExpr(vId, ident"kind")

  for kindIdx in start.ord .. stop.ord:
    let kind = cast[AnyKind](kindIdx)
    caseBody.add nnkOfBranch.newTree(
      newLit kind,
      newCall(typId,
        newDotExpr(vId, ident "get" & kind.getTypeName)
      )
    )
  caseBody.add nnkElse.newTree(
    quote do:
      doAssert false; default `typId`
  )

  procBody.add caseBody

  result = quote do:
    proc `procName`(`vId`: Any, `errMsgId`: string): `typId` = `procBody`


genParserOfRange(akInt, akInt64)
#genParserOfRange(akFloat, akFloat64)
genParserOfRange(akUInt, akUInt64)

template getString(s: SomeNumber): string = $s
template numParse(R){.dirty.} =
  template `get R`(s: SomeNumber, msgPre: string): R = R s

numParse BiggestInt
numParse BiggestUInt

template getAsBiggestInt(v: SomeNumber, res: var BiggestInt, msgPre: string): bool =
  res = BiggestInt v
  v is SomeInteger
proc getAsBiggestInt(v: Any, res: var BiggestInt, msgPre: string): bool =
  ## returns if is indeed int internal
  if v.kind in akFloat .. akFloat64:
    res = BiggestInt v.getBiggestFloat
    false
  else:
    res = v.getBiggestInt msgPre & v.kind.getTypeName
    true

template getAsBiggestFloat(v: SomeNumber, msgPre: string): float =
  float v
proc getAsBiggestFloat(v: Any, msgPre: string): float =
  let msg = msgPre & v.kind.getTypeName
  if v.kind in akFloat .. akFloat64:
    v.getBiggestFloat
  elif v.kind in akUInt .. akUInt64:
    float v.getBiggestUInt msg
  else:
    float v.getBiggestInt msg

#TODO:
#proc format_obj(v: Any): string = $v  # and for object type, etc.

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

proc getAsChar(s: SomeInteger): char =
  s.chkInRange 256:
    raise newException(TypeError, rng256ErrMsg)
  cast[char](s)

proc getAsChar(v: Any): char =
  ## byte_converter
  template doWithS(s): untyped =
    s.len.chkLen1
    s[0]
  case v.kind
  of akString:
    let s = v.getString
    doWithS s
  of akCString:
    let s = v.getCString
    doWithS s
  of akChar:
    v.getChar
  else:
    let i = getBiggestInt(v, rng256ErrMsg)
    getAsChar i

proc getAsChar(s: string|cstring): char =
  s.len.chkLen1
  s[0]

template raiseOverflowError(msg) =
  raise newException(OverflowDefect, msg)

const cRequiredMsg = "%c requires int or char"
template oa(v): untyped = v.toOpenArray(0, v.high)
proc getAsRune(v: Any|string|cstring|openArray[char]|SomeInteger): Rune =
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
      getAsRune v.getBiggestInt cRequiredMsg
  else:
    v.chkInRange 0x110000:
      raiseOverflowError "%c arg not in range(0x110000)"
    cast[Rune](v)

#[ FIXME: Error check cannot be handled as following, otherwise `StrLike` like
  `PyBytes` won't work but raise `TypeError` shown as below
template getAsRune[T](v: T): Rune =
  {.error: "TypeError: %c requires an int or a unicode character, not " & $T.}
]#
template mistype(TT; R; msgWithT){.dirty.} =
  proc `getAs R`[T: TT](v: T): R =
    raise newException(TypeError, msgWithT)

mistype SomeFloat, Rune, cRequiredButNotPre & $T
mistype SomeFloat, char, cRequiredMsg

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
    #[: openArray[Any|string]|Getitemable[string, Any|string]
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
    var (arglen, argidx) = (args.len, 0)
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
  when compiles(InnerVal("")):
    template getString(s: InnerVal): string = 
      when InnerVal is string: s
      else: string s
    template genErr(R){.dirty.} =
      proc `get R`(v: InnerVal, msgPre: string): R =
        raise newException(TypeError, msgPre & $InnerVal)
    genErr BiggestUInt
    genErr BiggestInt
    template err = raise newException(TypeError, msgPre & $InnerVal)
    proc getAsBiggestInt(v: InnerVal, res: var BiggestInt, msgPre: string): bool = err
    proc getAsBiggestFloat(v: InnerVal, msgPre: string): float = err
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

      let realnumExpectedMsgPre = &"%{specifier} format: a real number is required, not "
      case specifier
      of 'r':
        let s = value.getString.reprCb
        result.formatValue s, spec
      of 'a':
        let s = value.getString.asciiCb
        result.formatValue s, spec
      of 's', 'b':
        var s = value.getString
        if `disallow%b`:
          if specifier == 'b':
            raiseUnsupSpec(specifier, idx)

        result.formatValue s, spec
      of 'd', 'i', 'x', 'X', 'o':
        var i: BiggestInt
        let isInt = value.getAsBiggestInt(i, realnumExpectedMsgPre)
        if not isInt:
          let shallIntOnly = specifier not_in {'d', 'i'}
          if shallIntOnly:
            raise newException(TypeError, &"%{specifier} format: an integer is required, not float")
          #XXX:
          #[here we cannot mixin `index()` as well as `int()` for `value`, so there's
            no need to check if `int` returns an integer, thus err msg can only be in one form (as used above)
            instead of a string interpolared by "a real number" and type of `value`
            ]#
        result.formatValue i, spec
      of 'u':
        let ui = value.getBiggestUInt(realnumExpectedMsgPre)
        result.formatValue ui, spec
      of 'f', 'F', 'e', 'E', 'g', 'G':
        let f = value.getAsBiggestFloat "must be real number, not "
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


proc mapTuple(cb, s, args: NimNode): NimNode =
    ## Helper function to format a string with a tuple.
    ## This is used to ensure compatibility with the original Python `%` formatting.
    result = newStmtList()
    let nargs = genSym(nskVar, "nargs")
    result.add newVarStmt(nargs, args)
    var ls = newNimNode nnkBracket
    let tupLen = args.getType().len - 1
    let toAnyId = bindSym("toAny")
    for i in 0..<tupLen:
      ls.add quote do:
        `toAnyId` `nargs`[`i`]
    result.add newCall(cb, s, ls)

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
    bind toAny
    when compiles(arg[""]):
      partial(s, arg)
    elif arg is string|S|SomeNumber:
      partial(s, [arg])
    else:
      var va = arg
      partial(s, [va.toAny])
  macro percentFormat(s: S, args: tuple): S =
    bind mapTuple
    bind bindSym
    mapTuple bindSym"partial", s, args

  macro `%`*(s: S, args: untyped): S =
    bind kind, nnkTableConstr, bindSym, newCall
    bind toTableWithValueTypeAny
    if args.kind == nnkTableConstr:
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
