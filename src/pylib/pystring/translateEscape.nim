
import std/macros
import std/strformat

type LLineInfo = object
  filename: string
  line, col: int

proc lexLineInfoFrom(l: LineInfo): LLineInfo =
  result.filename = l.filename
  result.col = l.column
  result.line = l.line

# compiler/lineinfos.nim
type
  TMsgKind = enum
    errGenerated

type
  Token = object     # a Nim token
    literal: string  # the parsed (string) literal
  
  Lexer = object
    bufLen: int
    bufpos: int
    buf: string

    lineInfo: LLineInfo

proc newLexer(s: string): Lexer =
  result.buf = s
  result.bufLen = s.len

func lexMessage(L: Lexer, msg: TMsgKind, arg = "") =
  let info = L.lineInfo
  # when is multiline string, we cannot know where the position is,
  #  as Nim has been translated multiline as single-line.
  #let col = info.col+L.bufpos+1  # plus 1 to become 1-based
  let errMsg = '\n' & fmt"""
File "{info.filename}", line {info.line}
  {arg}"""
  if msg == errGenerated:
    error errMsg
  else:
    debugEcho errMsg

func handleOctChars(L: var Lexer, xi: var int) =
  ## parse at most 3 chars
  for _ in 0..2:
    let c = L.buf[L.bufpos]
    if c notin {'0'..'7'}: break
    xi = (xi * 8) + (ord(c) - ord('0'))
    inc(L.bufpos)
    if L.bufpos == L.bufLen: break

func handleHexChar(L: var Lexer, xi: var int; position: int) =
  template invalid() =
    lexMessage(L, errGenerated,
      "expected a hex digit, but found: " & L.buf[L.bufpos] &
        "; maybe prepend with 0")

  case L.buf[L.bufpos]
  of '0'..'9':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('0'))
    inc(L.bufpos)
  of 'a'..'f':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('a') + 10)
    inc(L.bufpos)
  of 'A'..'F':
    xi = (xi shl 4) or (ord(L.buf[L.bufpos]) - ord('A') + 10)
    inc(L.bufpos)
  of '"', '\'':
    if position <= 1: invalid()
    # do not progress the bufpos here.
    if position == 0: inc(L.bufpos)
  else:
    invalid()

template ones(n): untyped = ((1 shl n)-1) # for utf-8 conversion

const
  CR = '\r'
  LF = '\n'
  FF = '\f'
  BACKSPACE = '\b'
  ESC = '\e'

func addUnicodeCodePoint(s: var string, i: int) =
  let i = cast[uint](i)
  # inlined toUTF-8 to avoid unicode and strutils dependencies.
  let pos = s.len
  if i <= 127:
    s.setLen(pos+1)
    s[pos+0] = chr(i)
  elif i <= 0x07FF:
    s.setLen(pos+2)
    s[pos+0] = chr((i shr 6) or 0b110_00000)
    s[pos+1] = chr((i and ones(6)) or 0b10_0000_00)
  elif i <= 0xFFFF:
    s.setLen(pos+3)
    s[pos+0] = chr(i shr 12 or 0b1110_0000)
    s[pos+1] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i and ones(6) or 0b10_0000_00)
  elif i <= 0x001FFFFF:
    s.setLen(pos+4)
    s[pos+0] = chr(i shr 18 or 0b1111_0000)
    s[pos+1] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i and ones(6) or 0b10_0000_00)
  elif i <= 0x03FFFFFF:
    s.setLen(pos+5)
    s[pos+0] = chr(i shr 24 or 0b111110_00)
    s[pos+1] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i and ones(6) or 0b10_0000_00)
  elif i <= 0x7FFFFFFF:
    s.setLen(pos+6)
    s[pos+0] = chr(i shr 30 or 0b1111110_0)
    s[pos+1] = chr(i shr 24 and ones(6) or 0b10_0000_00)
    s[pos+2] = chr(i shr 18 and ones(6) or 0b10_0000_00)
    s[pos+3] = chr(i shr 12 and ones(6) or 0b10_0000_00)
    s[pos+4] = chr(i shr 6 and ones(6) or 0b10_0000_00)
    s[pos+5] = chr(i and ones(6) or 0b10_0000_00)

func getEscapedChar(L: var Lexer, tok: var Token) =
  inc(L.bufpos)               # skip '\'
  template uniOverErr(curVal: string) =
    lexMessage(L, errGenerated,
      "Unicode codepoint must be lower than 0x10FFFF, but was: " & curVal)
    
  case L.buf[L.bufpos]
  of 'n', 'N':
    tok.literal.add('\L')
    inc(L.bufpos)
  of 'p', 'P':
    tok.literal.add("\p")
    inc(L.bufpos)
  of 'r', 'R', 'c', 'C':
    tok.literal.add(CR)
    inc(L.bufpos)
  of 'l', 'L':
    tok.literal.add(LF)
    inc(L.bufpos)
  of 'f', 'F':
    tok.literal.add(FF)
    inc(L.bufpos)
  of 'e', 'E':
    tok.literal.add(ESC)
    inc(L.bufpos)
  of 'a', 'A':
    tok.literal.add('\a')
    inc(L.bufpos)
  of 'b', 'B':
    tok.literal.add(BACKSPACE)
    inc(L.bufpos)
  of 'v', 'V':
    tok.literal.add('\v')
    inc(L.bufpos)
  of 't', 'T':
    tok.literal.add('\t')
    inc(L.bufpos)
  of '\'', '\"':
    tok.literal.add(L.buf[L.bufpos])
    inc(L.bufpos)
  of '\\':
    tok.literal.add('\\')
    inc(L.bufpos)
  of 'x', 'X':
    inc(L.bufpos)
    var xi = 0
    handleHexChar(L, xi, 1)
    handleHexChar(L, xi, 2)
    tok.literal.add(chr(xi))
  of 'U':
    # \Uhhhhhhhh
    inc(L.bufpos)
    var xi = 0
    let start = L.bufpos
    for i in 0..7:
      handleHexChar(L, xi, i)
    if xi > 0x10FFFF:
      uniOverErr L.buf[start..L.bufpos-2]
    addUnicodeCodePoint(tok.literal, xi)
  of 'u':
    inc(L.bufpos)
    var xi = 0
    if L.buf[L.bufpos] == '{':
      inc(L.bufpos)
      let start = L.bufpos
      while L.buf[L.bufpos] != '}':
        handleHexChar(L, xi, 0)
      if start == L.bufpos:
        lexMessage(L, errGenerated,
          "Unicode codepoint cannot be empty")
      inc(L.bufpos)
      if xi > 0x10FFFF:
        uniOverErr L.buf[start..L.bufpos-2]
    else:
      handleHexChar(L, xi, 1)
      handleHexChar(L, xi, 2)
      handleHexChar(L, xi, 3)
      handleHexChar(L, xi, 4)
    addUnicodeCodePoint(tok.literal, xi)
  of '0'..'7':
    var xi = 0
    handleOctChars(L, xi)
    tok.literal.add(chr(xi))
  else: lexMessage(L, errGenerated, "invalid character constant")

func getString(L: var Lexer, tok: var Token) =
  var pos = L.bufpos

  while pos < L.bufLen:
    let c = L.buf[pos]
    if c == '\\':
      L.bufpos = pos
      getEscapedChar(L, tok)
      pos = L.bufpos
    else:
      tok.literal.add(c)
      pos.inc
  L.bufpos = pos

func getString(L: var Lexer): Token =
  L.getString result

func translateEscape*(pattern: string): string =
  ## like `translateEscapeWithErr` but without lineInfo error msg
  var L = newLexer pattern
  L.getString().literal

macro translateEscapeWithErr*(pattern: string): string =
  let info = pattern.lineInfoObj
  let linfo = lexLineInfoFrom info
  let sPattern = pattern.strVal
  var L = newLexer sPattern
  L.lineInfo = linfo
  let s = L.getString().literal
  result = newLit s
