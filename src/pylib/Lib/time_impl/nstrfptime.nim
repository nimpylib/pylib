## strftime, strptime
## 
## platform independent implementation.
import ./private/doc_utils

var docTableInner{.compileTime.}: DocTable
when defined(nimdoc):
  docTableInner = initDocTable(
    slurp"./doc/nstrfptime.rst", {
    "strptime": slurp"./doc/nstrptime.rst"
  })
# if let `const docTable = initDocTable(...)` shown in doc,
# a large lump of data will occur in doc.
const docTable* = docTableInner  ## used to transport doc string to outer module.

export fetchDoc

import std/strutils
import std/times

const NotImplDirectives* = {'j','w','y','U','Z'      
} ## Here are their concrete meanings in Python,
  ## as well as some notes about why they cannot be directly mapped to
  ## Nim's DateTime.format/parse.
  ## 
  ## The direct alternative value when formatting in Nim,
  ## if any, is introduced by `<-`:
  ##
  ## - j: Day of the year as a decimal number `[001,366]`. <- DateTime.yearday + 1
  ## - w: Weekday `[0(Sunday),6]`. <- (DateTime.weekday.int + 1) mod 7
  ## - y: Year without century as a decimal number `[00,99]`. <- DateTime.format"yy"
  ##   When parsing, C/Python's %y use 20th or 21th centry
  ##   depending on the value of %y
  ##   Nim's yy use the current century
  ## - U: Week number of the year (Sunday as the first day of the week)
  ##   as a decimal number `[00,53]`.
  ##   All days in a new year preceding the first Sunday are considered
  ##   to be in week 0.
  ##   Nim's V or VV is of range `[1,53]` (times.IsoWeekRange, get via DateTime.getIsoWeekAndYear)
  ##   and use Monday as the first day of a week.
  ##   (Nim's is iso-week, Python's is not)
  ## - Z: Time zone name (no characters if no time zone exists). Deprecated.
  ##   Impossible to implement without interacting with C lib.
  ##   Any way, it's deprecated.

func notImplErr(c: char) =
  var msg = "not implement format directives: %" & c
  if c == 'Z':
    msg.add ", which is deprecated by Python."
  assert false, msg

template raiseUnknownDirective(c: char, fmt: string) =
  raise newException(ValueError, "'$#' is a bad directive in format format: $#".format(c, repr(fmt)))

template raiseStrayPercent(fmt: string) =
  raise newException(ValueError, "stray % in format " & repr(fmt))

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
    noNimEquivHandle = notImplErr,
    handleUnknownDirective = raiseUnknownDirective,
    forParse: static[bool] = false,
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
      when forParse:
        raiseStrayPercent cstr
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
    else:
      handleUnknownDirective(c, cstr)
    i.inc


func strftime*(format: string, dt: DateTime): string
    {.fetchDoc(docTable).} =
  result = newStringOfCap format.len
  template handleSnippet(s, start, stop) =
    result.add s[start..<stop]
  template doWith(f) = result.add dt.format f
  template handlePercent = result.add '%'
  let iso_w_y = dt.getIsoWeekAndYear()
  template handleSomeAndUnknown(c: char, fmt: string) =
    case c
    of 'G':
      result.add $iso_w_y.isoyear
    of 'g':
      result.add ($iso_w_y.isoyear).substr(3)
    of 'V':
      result.add $iso_w_y.isoweek
    else:
      handlePercent
      result.add c
  cStyle format, handleSnippet, doWith, handlePercent,
    handleUnknownDirective=handleSomeAndUnknown

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

proc strptime*(dt: var DateTime, s: string, format_with_sp_asis: string)
    {.fetchDoc(docTable).} =
  let nformat = translate2Nim(format_with_sp_asis)
  dt = parse(s, nformat)
