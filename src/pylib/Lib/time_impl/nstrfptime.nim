## strftime, strptime
## 
## platform independent implementation.
import ./private/doc_utils

# if let:`const docTable = initDocTable(...)` shown in doc,
# a large lump of data will occur in doc.
let docTableInner{.compileTime.} =
  when defined(nimdoc):
    const
      strfpDoc = slurp"./doc/nstrfptime.rst"
      strpDoc = slurp"./doc/nstrptime.rst"
    static: # `slurp` will fail silently if such a file doesn't exist
      assert strfpDoc.len != 0
      assert strpDoc.len != 0
    initDocTable(
      strfpDoc, {
      "strptime": strpDoc
    })
  else:
    default DocTable
let docTable*{.compileTime.} = docTableInner ##\
## used to transport doc string to outer module.

export fetchDoc

import std/strutils
import std/times

const NotImplDirectives* = {'y', 'Z'      
} ## Here are their concrete meanings in Python,
  ## as well as some notes about why they cannot be directly mapped to
  ## Nim's DateTime.format/parse.
  ## 
  ## The direct alternative value when formatting in Nim,
  ## if any, is introduced by `<-`:
  ##
  ## - y: Year without century as a decimal number `[00,99]`. <- DateTime.format"yy"
  ##   When parsing, C/Python's %y use 20th or 21th centry
  ##   depending on the value of %y
  ##   Nim's yy use the current century
  ## - Z: Time zone name (no characters if no time zone exists). Deprecated.
  ##   However, this is supported in Lib/datetime
  ##
  ## Following are strftime only currently:
  ##
  ## - j: Day of the year as a decimal number `[001,366]`. <- DateTime.yearday + 1
  ## - u: Weekday `[0(Monday), 6]`. <- DateTime.weekday.int
  ## - w: Weekday `[0(Sunday),6]`. <- (DateTime.weekday.int + 1) mod 7
  ## - U: Week number of the year (Sunday as the first day of the week)
  ##   as a decimal number `[00,53]`.
  ##   All days in a new year preceding the first Sunday are considered
  ##   to be in week 0.

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
  Tp = "H:m:s"
  Tf = "HH:mm:ss"
  `%Y` = "uuuu"
const
  `xp` = "ddd M d"
  `xf` = "ddd MM dd"
  `Xp` = Tp
  `Xf` = Tf
  `space%Y` = ' ' & `%Y`
  `cp` = xp & ' ' & Xp & `space%Y`
  `cf` = xf & ' ' & Xf & `space%Y`

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
    # Year
    of 'Y': doWith `%Y`
    # Month
    of 'b': doWith "MMM"
    of 'B': doWith "MMMM"
    of 'm': doWith fmtOrP "MM"
    # Day
    of 'd': doWith fmtOrP "dd"
    # Weekday
    of 'a': doWith "ddd"
    of 'A': doWith "dddd"
    # Hour, Minute, Second
    of 'H': doWith fmtOrP "HH"
    of 'I': doWith fmtOrP "hh"
    of 'M': doWith fmtOrP "mm"
    of 'S': doWith fmtOrP "ss"
    # Microsecond
    of 'f': doWith "ffffff"  # XXX: on Python %f is not for time.strftime()
    # Other
    of 'z': doWith "ZZZ"
    of 'p': doWith "tt"
    of 'x': doWith fmtOrP(xf, xp)
    of 'X': doWith fmtOrP(Xf, Xp)
    of 'c': doWith fmtOrP(cf, cp)
    of 'F': doWith fmtOrP(`%Y` & "-MM-dd", `%Y` & "-M-d")
    of 'T': doWith fmtOrP(Tf, Tp)
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
  template weekday2w(weekday: WeekDay): int = (weekday.int+1) mod 7
  template `%w`: int = weekday2w dt.weekday
  template `%j`: int = dt.yearday.int + 1
  template handleSomeAndUnknown(c: char, fmt: string) =
    template push(i: int) = result.add $i
    template push(i: int, n: int{lit}) = result.add intToStr(i, n)
    template push(s: char|string) = result.add s
    case c
    # Year
    of 'G': push iso_w_y.isoyear.int, 4
    of 'g': push ($iso_w_y.isoyear).substr(2)
    # Week
    of 'V': push iso_w_y.isoweek.int, 2
    of 'U': push (dt.yearday.int - `%w` + 7) div 7, 2
    # Day
    of 'j': push `%j`, 3
    # Weekday
    of 'u': push dt.weekday.int + 1
    of 'w': push `%w`
    else:
      handlePercent
      push c
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
