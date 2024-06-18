import std/strutils
import std/times
import ./asctimeImpl

func invalidFormat =
  raise newException(ValueError, "Invalid format string")

template cStyle(cstr: string;
    handleSnippet; # Callable[[string, int, int], void]
    doWith;  # Callable[[string], void]; handle Nim's formatStr
    handleDateTime; # Callable[[], void]
    handlePercent;   # Callable[[], void]
    forParse: static[bool] = false
    ) =
  let le = cstr.len
  template fmtOrP(fmt): string =
    when forParse: fmt[1..^1] else: fmt
  let hi = le - 1
  var i = 0
  while i < le:
    let idx = cstr.find('%', i)
    if idx == -1:
      handleSnippet cstr, i, le
      return
    if idx == hi:
      invalidFormat()
    if unlikely idx != 0:
      handleSnippet cstr, i, idx

    i = idx + 1
    let c = cstr[i]
    case c
    of '%': handlePercent()
    of 'Y': doWith "uuuu"
    of 'm': doWith fmtOrP "MM"
    of 'd': doWith fmtOrP "dd"
    of 'H': doWith fmtOrP "HH"
    of 'M': doWith fmtOrP "mm"
    of 'S': doWith fmtOrP "ss"
    of 'z': doWith "ZZZ"
    of 'a': doWith "ddd"
    of 'A': doWith "dddd"
    of 'b': doWith "MMM"
    of 'B': doWith "MMMM"
    of 'I': doWith fmtOrP "hh"
    of 'p': doWith "tt"
    of 'c': handleDateTime()
    else: invalidFormat()
    i.inc


func strftime*(format: string, dt: DateTime): string =
  ## escape C style to a string that can be accepted by std/time
  result = newStringOfCap format.len
  template handleSnippet(s, start, stop) =
    result.add s[start..<stop]
  template doWith(f) = result.add dt.format f
  template handleDateTime = asctimeImpl result, dt
  template handlePercent = result.add '%'
  cStyle format, handleSnippet, doWith, handleDateTime, handlePercent

const `fmt for %c` = "ddd M d h:m:s nnnn"
proc translate2Nim(cstr: string): string =
  ## translate to Nim std/time's format
  result = newStringOfCap cstr.len  # shall be more.
  template handleSnippet(_, start, stop) =
    result.add '\''
    for i in start..<stop:
      let c = cstr[i]
      if c == '\'': result.add "''"
      else: result.add c
    result.add '\''
  template handleDateTime =
    result.add `fmt for %c`
  template doWith(f) =
    result.add f
  template handlePercent = result.add "'%'"
  cStyle cstr, handleSnippet, doWith, handleDateTime, handlePercent,
    forParse=true

proc strptime*(dt: var DateTime, s: string, format: string) =
  let nformat = translate2Nim(format)
  dt = parse(s, nformat)
