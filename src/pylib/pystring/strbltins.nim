
import std/strutils
from std/unicode import runeAt, utf8, runeLen, Rune, `$`
import ./strimpl
from ../pyerrors import TypeError

func reversed*(s: PyStr): PyStr =
  unicode.reversed s

func chr*(a: SomeInteger): PyStr =
  if a.int notin 0..0x110000:
    raise newException(ValueError, "chr() arg not in range(0x110000)")
  result = $Rune(a)


func ord1*(a: PyStr): int =
  runnableExamples:
    assert ord1("123") == ord("1")
  result = system.int(a.runeAt(0))

proc ord*(a: PyStr): int =
  ## Raises TypeError if len(a) is not 1.
  runnableExamples:
    doAssert ord("δ") == 0x03b4

  when not defined(release):
    let ulen = a.len
    if ulen != 1:
      raise newException(TypeError, 
        "TypeError: ord() expected a character, but string of length " & $ulen & " found")
  result = ord1 a

proc rawReprImpl(us: string
  ,e1: static[bool] = false # if skip(not escape) `'`(single quotation mark)
  ,e2: static[bool] = false # if skip(not escape) `"`(double quotation mark)
  ,escapeUnicode: static[bool] = false
): string =
  template add12(s: string, c: char) =
    when e1:
      if c == '\'':
        result.add '\''
        continue
    when e2:
      if c == '"':
        result.add '"'
        continue
    result.addEscapedChar c
  for s in us.utf8:
    if s.len == 1:  # is a ascii char
      when defined(useNimCharEsc): s.add12 s[0]
      else:
        let c = s[0]
        if c == '\e': result.add "\\x1b"
        else: s.add12 c
    else:
      when escapeUnicode:
        if s.len<4:
          result.add r"\u" & ord1(s).toHex(4).toLowerAscii
        else:
          result.add r"\U" & ord1(s).toHex(8)
      else:
        result.add s

proc raw_ascii(us: string
  ,e1: static[bool] = false
  ,e2: static[bool] = false
): string =
  us.rawReprImpl(e1, e2, escapeUnicode = true)

proc raw_repr(us: string
  ,e1: static[bool] = false
  ,e2: static[bool] = false
): string =
  us.rawReprImpl(e1, e2, escapeUnicode = false)

template implWith(a; rawImpl): untyped =
  let us = a  # if a is an expr, avoid `a` being evaluated multiply times 
  when defined(singQuotedStr):
    '\'' & rawImpl(us) & '\''
  else:
    if '"' in us:
      '\'' & rawImpl(us, e2 = true) & '\''
    else:
      if '\'' in us:
        '"' & rawImpl(us, e1 = true) & '"'
      else: # neither ' nor "
        '\'' & rawImpl(us) & '\''

func repr*(x: PyStr): string =
  ## Overwites `system.repr` for `PyStr`
  ## 
  ## The same as `proc ascii`_ except for unicode chars being remained AS-IS.
  implWith($x, raw_repr)

func pyrepr*(s: StringLike): PyStr =
  ## Shortcut for `str(repr(str(s)))`
  runnableExamples:
    # NOTE: string literal's `repr` is `system.repr`, as following. 
    assert repr("\"") == "\"\\\"\""   # string literal of "\""
    # use pyrepr for any StringLike and returns a PyStr
    assert pyrepr("\"") == "'\"'"
  str implWith($s, raw_repr)

proc ascii*(us: string): string=
  ##   nim's Escape Char feature can be enabled via `-d:useNimCharEsc`,
  ##     in which '\e' (i.e.'\x1B' in Nim) will be replaced by "\\e"
  ## 
  ## define `singQuotedStr` to get better performance
  ## but it'll be different from python's. See the examples following:
  runnableExamples:
    when defined(nimPreviewSlimSystem):
      import std/assertions
    assert ascii("𐀀") == r"'\U00010000'"
    assert ascii("đ") == r"'\u0111'"
    assert ascii("和") == r"'\u548c'"
    let s = ascii("v我\n\e")
    when not defined(useNimCharEsc):
      let rs = r"'v\u6211\n\x1b'"
    else:
      let rs = r"'v\u6211\n\e'"
    assert s == rs
    assert ascii("\"") == "'\"'"
    assert ascii("\"'") == "'\"\\''"
    let s2 = ascii("'")
    when not defined(singQuotedStr):
      let rs2 = "\"'\""
    else:
      let rs2 = r"'\''"
    assert s2 == rs2
  us.implWith raw_ascii

func ascii*(a: PyStr): PyStr =
  ascii a

template ascii*(c: char): PyStr =
  ## we regard 'x' as a str (so as in python)
  runnableExamples:
    when defined(nimPreviewSlimSystem):
      import std/assertions
    assert ascii('c') == "'c'"
  ascii($c)

template ascii*(a: untyped): string =
  runnableExamples:
    when defined(nimPreviewSlimSystem):
      import std/assertions
    assert ascii(6) == "6"
  ascii(repr(a))

