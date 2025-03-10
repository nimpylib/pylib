
import std/strutils
import std/options
from std/tables import contains
import ./n_chainmap
export n_chainmap.`[]`, n_chainmap.contains

template splitlines(a; keepends = false): untyped =
  a.splitLines(keepEol = keepends)

proc lenSumExceptLast(a: openArray[string]): int =
  for i in a.toOpenArray(0, a.high - 1):
    result += i.len

proc invalidFormatString(formatstr: string, i: int) =
  let
    lines = formatStr[0..^i].splitlines(keepends=true)
    (colno, lineno) =
      if lines.len == 0: (1, 1)
      else: (i - lenSumExceptLast(lines), len(lines))
  raise newException(ValueError,
    "Invalid placeholder in string: line " & $lineno &
    ", col " & $colno
  )

proc raiseKeyError(key: string) =
  raise newException(KeyError, $key)

const
  Delimiter* = '$'
  Braces = (start:'{', stop:'}')

type ExcHandle = ref object of RootObj
  hasExc*: bool
using self: ExcHandle
proc flagExc(self) = self.hasExc = true
method invalidKey(self; key: string){.base.} = self.flagExc
method invalidFormatString(self; formatstr: string, idx: int){.base.} = self.flagExc

type RaisesExcHandle = ref object of ExcHandle
using self: RaisesExcHandle
method invalidKey(self; key: string) = self.flagExc; raiseKeyError(key)
method invalidFormatString(self; formatstr: string, idx: int) =
  self.flagExc
  invalidFormatString(formatstr, idx)

proc initIgnoreExcHandle*: ExcHandle = ExcHandle()
proc initRaisesExcHandle*: ExcHandle = RaisesExcHandle()

type
  SubsCfg* = ref object of RootObj
    ## for `is_valid()`
    delimiter*: char
    excHandle*: ExcHandle
using self: SubsCfg
template noop = discard
method addSnippet(self; s: string){.base.} = noop()
proc addSnippet(self; c: char) = self.addSnippet $c  ## XXX: impr-me
template nolookup[M](self; a: M; key: string; hasBrace: static[bool]) = noop()

type Subs* = ref object of SubsCfg
  ## for `substitute()`
  res: string
using self: Subs
#proc `$`(self): string = self.res
method addSnippet(self; s: string) = self.res.add s
proc lookup[M](self; a: M; key: string; hasBrace: static[bool]) =
  if key in a:
    self.res.add:
      when compiles(str(a[key])): $str(a[key])
      else: $a[key]
  else:
    self.excHandle.invalidKey(key)
    self.addSnippet self.delimiter
    when hasBrace: self.addSnippet Braces.start
    self.addSnippet key
    when hasBrace: self.addSnippet Braces.stop

type GetIdent* = ref object of SubsCfg
  ## for `get_identifiers()`
  ## excHandle shall ignore ValueError, too
using self: GetIdent
method addSnippet(self; s: string) = discard
template nolookupButAdd(self; _: auto; key: string; _: static[bool]) =
  yield key

proc resetSubsCfg*(cfg: SubsCfg; excHandle = initRaisesExcHandle(), delimiter = Delimiter) =
  cfg.excHandle = excHandle
  cfg.delimiter = delimiter

proc initSubsCfg*(excHandle = initRaisesExcHandle(), delimiter = Delimiter): SubsCfg =
  result.resetSubsCfg(excHandle, delimiter)

template handle*[M](s: SubsCfg, formatstr: string, m: M;
    lookup#[: proc(self: SubsCfg; a: M; key: string; hasBrace: static[bool])]#) =
  ## .. note:: this differs Nim's std/strutils `%`
  const
    PatternStartChars = {'a'..'z', 'A'..'Z', '\128'..'\255', '_'} 
    PatternChars = PatternStartChars + { '0'..'9' }
  var i = 0

  template lookupBy(offset = 0) =
    var j = i+1+offset
    while j < formatstr.len and formatstr[j] in PatternChars: inc(j)
    let key = substr(formatstr, i+1+offset, j-1)
    s.lookup m, key, offset == 1
    i = j + offset

  while i < len(formatstr):
    if formatstr[i] == s.delimiter and i+1 < len(formatstr):
      let cur = formatstr[i+1]
      case cur
      of Braces.start:
        let curIdx = i
        lookupBy 1
        if formatstr[i-1] != Braces.stop:
          s.excHandle.invalidFormatString(formatstr, curIdx)
      of PatternStartChars: lookupBy 0
      elif cur == s.delimiter:
        s.addSnippet s.delimiter
        inc(i, 2)
      else:
        s.excHandle.invalidFormatString(formatstr, i)
        inc(i)
    else:
      s.addSnippet formatstr[i]
      inc(i)

proc substituteAux*[M](templ: string, m: M;
    excHandle = initRaisesExcHandle(); delimiter = Delimiter
): string =
  let cfg = Subs()
  cfg.resetSubsCfg(excHandle, delimiter)
  cfg.handle templ, m, lookup
  cfg.res

const DummyM = 0

proc isValid*(templ: string): bool =
  let cfg = SubsCfg()
  cfg.resetSubsCfg(initIgnoreExcHandle())
  cfg.handle templ, DummyM, nolookup
  not cfg.excHandle.hasExc

iterator getIdentifiers*(templ: string): string =
  let cfg = SubsCfg()
  cfg.resetSubsCfg(initIgnoreExcHandle())
  cfg.handle templ, DummyM, nolookupButAdd
