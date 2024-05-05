
import std/strutils
from std/unicode import runeAt, utf8, runeLen, Rune, `$`
import ./strimpl

func chr*(a: SomeInteger): PyStr =
  if a.int notin 0..0x110000:
    raise newException(ValueError, "chr() arg not in range(0x110000)")
  result = $Rune(a)


func ord1*(a: PyStr): int =
  runnableExamples:
    assert ord1("123") == ord("1")
  result = system.int(a.runeAt(0))

type
  TypeError* = object of CatchableError

proc ord*(a: PyStr): int =
  runnableExamples:
    doAssert ord("δ") == 0x03b4
    when not defined(release):
      doAssertRaises TypeError:
        discard ord("12")

  when not defined(release):
    let ulen = a.len
    if ulen != 1:
      raise newException(TypeError, 
        "TypeError: ord() expected a character, but string of length " & $ulen & " found")
  result = ord1 a

proc raw_ascii(us: string
  ,e1: static[bool] = false # if skip(not escape) `'`(single quotation mark)
  ,e2: static[bool] = false # if skip(not escape) `"`(double quotation mark)
): string =
  template add12(s: string) =
    let c = s[0]
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
      when defined(useNimCharEsc): add12 s
      else:
        let c = s[0]
        if c == '\e': result.add "\\x1b"
        else: add12 s
    elif s.len<4:
      result.add r"\u" & ord1(s).toHex(4).toLowerAscii
    else:
      result.add r"\U" & ord1(s).toHex(8)

proc ascii*(us: string): string=
  ##   nim's Escape Char feature can be enabled via `-d:useNimCharEsc`,
  ##     in which '\e' (i.e.'\x1B' in Nim) will be replaced by "\\e"
  ##   define singQuotedStr to get better performance but it'll be different from python's. See the `runnableExamples`
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

  when defined(singQuotedStr):
    '\'' & raw_ascii(us) & '\''
  else:
    if '"' in us:
      '\'' & raw_ascii(us, e2 = true) & '\''
    else:
      if '\'' in us:
        '"' & raw_ascii(us, e1 = true) & '"'
      else: # neither ' nor "
        '\'' & raw_ascii(us) & '\''


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
  raw_ascii($a)

