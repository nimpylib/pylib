## `str.format`
## 
## NOTE: only str in Python has `format` method, not bytes nor bytearray.
import std/strformat
import std/[
  parseutils, macros,
  tables, hashes
]
import ./formats
export formats

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

template formatCallIdent: NimNode = ident"formatValue"
template formatAltCallIdent: NimNode = ident"format"

proc pyformatImplAux*(s: string, args: seq[NimNode], kw: Kw): NimNode =
  ##[
    if -d:pylibUseFormatValue, use `formatValue` instead of `format` for formatting.

    Convertion is not supported yet (like `!r`).
  ]##
  # XXX: current impl is char-based for
  # str snippets between interpolations snippets,
  # and will generate too much lines of `<str>.add('<c>')` in generated code
  # TODO: rewrite to add via substr
  template addNode(res: NimNode, expAdd: NimNode, format_spec: NimNode) =
    result.add when defined(pylibUseFormatValue):
      newCall(formatCallIdent, res,
        expAdd,
        format_spec
      )
    else:
      let strAdd = newCall(formatAltCallIdent, expAdd, format_spec)
      newCall("add", res, strAdd)
  
  let res = genSym(nskVar, "formatRes")
  result = newStmtList()
  result.add newVarStmt(res, newCall(bindSym"newStringOfCap",
                                     newLit(s.len)))
  template parseSpec: string =
    var format_spec = ""
    if s[curIdx] == SpecSep:
      curIdx.inc s.parseUntil(format_spec, EndCh, curIdx)
    format_spec

  template pushIdent(identS: string) =
    let fspec = parseSpec()
    res.addNode kw[ ident(identS) ], newLit fspec
  template pushIdx(idx: int) =
    let fspec = parseSpec()
    res.addNode args[idx], newLit fspec
  
  template add(_: NimNode, cs: char|string) =
    result.add newCall(bindSym"add", res, newLit(cs))
  # minic that `result` is a string
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
      result.add c
      curIdx.inc
  result.add res
  result = newBlockStmt result

macro pyformat*(s: static[string], argKw: varargs[untyped]): string =
  let
    leArgKw = argKw.len
    leKw = leArgKw div 3
    leArg = leArgKw - leKw
  var
    args = newSeqOfCap[NimNode] leArg
    kw = newKw leKw

  for i in argKw:
    case i.kind
    of nnkExprEqExpr:
      kw[i[0]] = i[1]
    of nnkIdent:
      args.add i
    else:
      # maybe some checks here?
      args.add i
      
  result = s.pyformatImplAux(args, kw)


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
