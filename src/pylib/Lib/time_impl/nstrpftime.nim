import std/strutils
import std/times

const NotImplDirectives* = {
   'j' # Day of the year as a decimal number [001,366]. <- DateTime.yearday + 1
  ,'w' # Weekday [0(Sunday),6]. <- (DateTime.weekday.int + 1) mod 7
  ,'y' # Year without century as a decimal number [00,99]. <- "yy"
       # When parsing, C/Python's %y use 20th or 21th centry
       # depending on the value of %y
       # Nim's yy use the current century
  ,'U' # Week number of the year (Sunday as the first day of the week) <- ?
       # as a decimal number [00,53].
       # All days in a new year preceding the first Sunday are considered
       # to be in week 0.
       # Nim's V or VV seems to be of range [1,53]
       # and use Monday as the first day of a week.
       #(Nim's is iso-week, donno if Python's is)
  ,'Z' # Time zone name (no characters if no time zone exists). Deprecated.
       # Impossible to implement without interacting with C lib.
       # Any way, it's deprecated.
}

func notImplErr(c: char) =
  var msg = "not implement format directives: %" & c
  if c == 'Z':
    msg.add ", which is deprecated by Python."
  assert false, msg
func invalidFormat =
  raise newException(ValueError, "Invalid format string")

const
  `xp` = "ddd M d"
  `xf` = "ddd MM dd"
  `Xp` = "H:m:s uuuu"
  `Xf` = "HH:mm:ss uuuu"
  `cp` = xp & ' ' & Xp
  `cf` = xf & ' ' & Xf

template cStyle(cstr: string;
    handleSnippet; # Callable[[string, int, int], void]
    doWith;  # Callable[[string], void]; handle Nim's formatStr
    handlePercent;   # Callable[[], void]
    forParse: static[bool] = false,
    noNimEquivHandle = notImplErr
    ) =
  let le = cstr.len
  template fmtOrP(fmt): string =
    when forParse: fmt[1..^1] else: fmt
  template fmtOrP(fmt, parse): string =
    when forParse: parse else: fmt
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
    of 'f': doWith "ffffff"  # XXX: on Python %f is not for time.strftime()
    of 'z': doWith "ZZZ"
    of 'a': doWith "ddd"
    of 'A': doWith "dddd"
    of 'b': doWith "MMM"
    of 'B': doWith "MMMM"
    of 'I': doWith fmtOrP "hh"
    of 'p': doWith "tt"
    of 'x': doWith fmtOrP(xf, xp)
    of 'X': doWith fmtOrP(Xf, Xp)
    of 'c': doWith fmtOrP(cf, cp)
    of NotImplDirectives:
      noNimEquivHandle c
    else: invalidFormat()
    i.inc


func strftime*(format: string, dt: DateTime): string =
  ## escape C style to a string that can be accepted by std/time
  result = newStringOfCap format.len
  template handleSnippet(s, start, stop) =
    result.add s[start..<stop]
  template doWith(f) = result.add dt.format f
  template handlePercent = result.add '%'
  cStyle format, handleSnippet, doWith, handlePercent

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
  template doWith(f) =
    result.add f
  template handlePercent = result.add "'%'"
  cStyle cstr, handleSnippet, doWith, handlePercent, forParse=true

proc strptime*(dt: var DateTime, s: string, format_with_sp_asis: string) =
  ## .. include:: ./nstrptimeDiff.rst
  let nformat = translate2Nim(format_with_sp_asis)
  dt = parse(s, nformat)
