
import std/strutils
import std/options
from std/tables import contains

template splitlines(a; keepends = false): untyped =
  a.splitLines(keepEol = keepends)

proc lenSumExceptLast(a: openArray[string]): int =
  for i in a.toOpenArray(0, a.high - 1):
    result += i.len

proc invalidFormatString*(formatstr: string, i: int) =
  let
    lines = formatStr[0..^i].splitlines(keepends=true)
    (colno, lineno) =
      if lines.len == 0: (1, 1)
      else: (i - lenSumExceptLast(lines), len(lines))
  raise newException(ValueError,
    "Invalid placeholder in string: line " & $lineno &
    ", col " & $colno
  )
proc supressInvalidFormatString*(_: string, _: int) = discard

proc noraiseKeyError*(key: string) = discard
proc raiseKeyError*(key: string) =
  raise newException(KeyError, $key)

const
  Delimiter* = '$'
  Braces = (start:'{', stop:'}')

proc addTemplSub*[M](s: var string, formatstr: string, a: M;
    invalidKey = raiseKeyError; delimiter = Delimiter) =
  ## The same as `add(s, Template(formatstr).substitute(a)`, but more efficient.
  ## .. note:: this differs Nim's std/strutils `%`
  const
    PatternStartChars = {'a'..'z', 'A'..'Z', '\128'..'\255', '_'} 
    PatternChars = PatternStartChars + { '0'..'9' }
  var i = 0

  template lookup(offset = 0) =
    var j = i+1+offset
    while j < formatstr.len and formatstr[j] in PatternChars: inc(j)
    let key = substr(formatstr, i+1+offset, j-1)
    if key in a: s.add a[key]
    else:
      invalidKey(key)
      s.add delimiter
      when offset == 1: s.add Braces.start
      s.add key
      when offset == 1: s.add Braces.stop
    i = j + offset

  while i < len(formatstr):
    if formatstr[i] == delimiter and i+1 < len(formatstr):
      let cur = formatstr[i+1]
      case cur
      of Braces.start:
        let curIdx = i
        lookup 1
        if formatstr[i-1] != Braces.stop:
          invalidFormatString(formatstr, curIdx)
      of PatternStartChars: lookup 0
      elif cur == delimiter:
        add s, delimiter
        inc(i, 2)
      else:
        invalidFormatString(formatstr, i)
    else:
      add s, formatstr[i]
      inc(i)

proc substituteAux*[M](templ: string, m: M;
    invalidKey = raiseKeyError;
    invalidFormatString = invalidFormatString;
    delimiter = Delimiter
): string =
  result.addTemplSub(templ, m, invalidKey)
