

import std/[strutils, unicode]

func ord1(a: string): int =
  runnableExamples:
    assert ord1("123") == ord("1")
  result = system.int(a.runeAt(0))

func pyasciiImpl*(us: string): string =
  ## Python's `ascii` impl
  ## 
  ## Note this assumes `us` is already processed
  ##  by `repr`
  ## i.e., this only escape
  ## the non-ASCII characters in `us` using \x, \u, or \U escapes
  ## and doesn't touch ASCII characters.
  for s in us.utf8:
    if s.len == 1:  # is a ascii char
      let
        c = s[0]
        cOrd = c.uint8
      if cOrd > 127:
        result.add r"\x" & cOrd.toHex(2).toLowerAscii
      else:
        result.add c
    elif s.len < 4:
      result.add r"\u" & ord1(s).toHex(4).toLowerAscii
    else:
      result.add r"\U" & ord1(s).toHex(8)

