## `str.format`
## 
## NOTE: only str in Python has `format` method, not bytes nor bytearray.
import std/strformat
import std/[
  parseutils, macros,
  tables, hashes
]
import ../nimpatch/typeinfo
import ./formats
export formats
import ./format_utils
import ./formatValue_Any

type
  Ident = distinct NimNode
  Kw = TableRef[Ident, NimNode]

converter toIdent(n: NimNode): Ident =
  expectKind n, {nnkIdent, nnkSym}
  Ident(n)

proc hash(n: Ident): int = hash n.NimNode.strVal
proc `==`(a, b: Ident): bool = a.NimNode == b.NimNode
proc newKw(cap=defaultInitialSize): Kw =
  newTable[Ident, NimNode](defaultInitialSize)

const
  BegCh = '{'
  EndCh = '}'
  SpecSep = ':'

template errFormat(s, idx): string = "at idx " & $idx & " of \"" & s & '"'
proc raiseFormatError(s: string, idx: int, additionInfo: string) =
  raise newException(ValueError,  errFormat(s, idx) & ": " & additionInfo)
proc raiseFormatError(s: string, idx: int) =
  raise newException(ValueError, errFormat(s, idx))

proc expectCh(s: string, idx: int, ch: char) =
  if s[idx] != ch:
    raiseFormatError(s, idx, '`' & ch & "` expected")


template pyformatImpl(s, args, kw): untyped{.dirty.} =
  ##[
    if -d:pylibUseFormatValue, use `formatValue` instead of `format` for formatting.

    Convertion is not supported yet (like `!r`).
  ]##
  const compileTime = typeof(result) is NimNode
  when compileTime:
    template format(v, spec: NimNode): NimNode =
      newCall(bindSym"format", v, spec)
  else:
    template ident(s: string): string = s

  # minic that `result` is a string
  template addNode(res, expAdd, format_spec) =
    when defined(pylibUseFormatValue): formatValue(res, expAdd, format_spec)
    else: res &= format(expAdd, format_spec)

  template parseSpec: untyped =
    var format_spec = ""
    if s[curIdx] == SpecSep:
      curIdx.inc s.parseUntil(format_spec, EndCh, curIdx)
    when compileTime: newLit format_spec
    else: format_spec

  template pushIdent(identS: string) =
    let fspec = parseSpec()
    result.addNode kw[ ident(identS) ], fspec
  template pushIdx(idx: int) =
    let fspec = parseSpec()
    result.addNode args[idx], fspec

  var curIdx = 0
  var
    varIdx = -1
    varAutoIdx = 0
    varIdent: string
  let slen = s.len
  while curIdx < slen:
    let c = s[curIdx]
    if c == BegCh:
      curIdx.inc
      case s[curIdx]
      of BegCh:
        result.add BegCh
        curIdx.inc
        continue
      of '0'..'9':
        let nDigits = parseInt(s, varIdx, curIdx)
        if nDigits == 0:
          raiseFormatError(s, curIdx, "int index expected")
        curIdx.inc nDigits
        pushIdx varIdx
        varIdx = -1
      else:
        let nAlpha = parseIdent(s, varIdent, curIdx)
        if nAlpha != 0:
          curIdx.inc nAlpha
          pushIdent varIdent
        else:
          case s[curIdx]
          of {SpecSep, EndCh}:
            pushIdx varAutoIdx
            varAutoIdx.inc
          else:
            raiseFormatError(s, curIdx)

      expectCh s, curIdx, EndCh
      curIdx.inc
    
    elif c == EndCh:
      result.add c
      curIdx.inc
      expectCh(s, curIdx, EndCh)
      curIdx.inc
    else:
      let startIdx = curIdx
      curIdx.inc s.skipUntil(BegCh, startIdx)
      result.addSubStr s, startIdx, curIdx

proc pyformatImplAux*(s: string, args: openArray[NimNode], kw: Kw): NimNode =
  result = newLit ""
  pyformatImpl s, args, kw

proc pyformatImplAux*(s: string, args: openArray[Any], kw: GetitemableOfK[string]): string =
  result = newStringOfCap s.len
  pyformatImpl s, args, kw

func calLen(leArgKw: int): tuple[leArg, leKw: int]{.inline.} =
  let leKw = leArgKw div 3
  (leArgKw - leKw, leKw)

template pyformatAux(args, kw, addToArgs): untyped{.dirty.} =
  for i in argKw:
    case i.kind
    of nnkExprEqExpr:
      kw[i[0]] = i[1]
    of nnkIdent:
      addToArgs args, i
    else:
      # maybe some checks here?
      addToArgs args, i

macro pyformat*(s: static[string], argKw: varargs[untyped]): string =
  let t = calLen argKw.len
  var
    args = newSeqOfCap[NimNode] t.leArg
    kw = newKw t.leKw
  pyformatAux args, kw, add
  pyformatImplAux(s, args, kw)

# `toAny` only receive `var`, so we firstly put values on stack
proc addVar(resStmt: var NimNode, v: NimNode, bareName="tmp"): NimNode =
  result = genSym(nskVar, bareName)
  resStmt.add newVarStmt(result, v)

macro pyformat*(s: string, argKw: varargs[untyped]): string =
  ## for non-static `s`
  var
    args = newNimNode nnkBracket
    kw = newNimNode nnkTableConstr
  result = newStmtList()
  template wrapToAny(x): untyped =
    newCall(bindSym"toAny", x)
  template `[]=`(kw, k, v: NimNode) =
    let vId = result.addVar(v, k.strVal)
    kw.add nnkExprColonExpr.newTree(newLit k.strVal, vId.wrapToAny)
  template addAsAny(args, v: NimNode) =
    let vId = result.addVar(v)
    args.add vId.wrapToAny

  pyformatAux args, kw, addAsAny
  kw = quote do: toTable[string, Any](`kw`)
  result.add newCall(bindSym"pyformatImplAux", s, args, kw)

template pyformatMap*(s: static string, map: GetitemableOfK[string]): string =
  bind pyformatImplAux
  pyformatImplAux s, [], map
macro pyformatMap*(s: string, map: GetitemableOfK[string]): string =
  newCall(bindSym"pyformatImplAux", s, newNimNode nnkBracket, map)


when isMainModule:
  template check(b) =
    static:
      assert b
  check "ad 3 e" == "ad {} e".pyformat("3")
  check "ad 3 e 3" == "ad {0} e {0}".pyformat(3)
  check "ad 3 e 5 3" == "ad {0} e {a} {0}".pyformat(3, a=5)
  check "5,a" ==  "{},{}".pyformat(3+2,'a')
  let aa = 'c'
  assert "5,c" == "{},{}".pyformat(3+2, aa)

  var vs = "{},"
  assert "5,c" == (vs & "{}").pyformat(3+2, aa)
  vs.add "}}"
  assert "5,}}c" == (vs & "{}").pyformat(5, aa)
  assert "5,}}4" == (vs & "{aa}").pyformat(5, aa=4)

  let tab = {"a": 12}.toTable
  assert "^12$" == "^{a}$".pyformatMap(tab)
