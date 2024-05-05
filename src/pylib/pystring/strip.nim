
import ./consts
import ./strimpl
from std/unicode import toRunes, Rune

func strip(s: PyStr, leading: static[bool] = true, trailing: static[bool] = true,
            chars: openArray[Rune] = unicodeSpaces): PyStr =
  ## Strips leading or trailing `chars` (default: whitespace characters)
  ## from `s` and returns the resulting string.
  ##
  ## If `leading` is true (default), leading `chars` are stripped.
  ## If `trailing` is true (default), trailing `chars` are stripped.
  ## If both are false, the string is returned unchanged.
  ##
  ## See also:
  ## * `strip proc<strbasics.html#strip,string,set[char]>`_ Inplace version.
  ## * `stripLineEnd func<#stripLineEnd,string>`_
  runnableExamples:
    let a = "  vhellov   "
    let b = strip(a)
    doAssert b == "vhellov"

    doAssert a.strip(leading = false) == "  vhellov"
    doAssert a.strip(trailing = false) == "vhellov   "

    doAssert b.strip(chars = {'v'}) == "hello"
    doAssert b.strip(leading = false, chars = {'v'}) == "vhello"

    let c = "blaXbla"
    doAssert c.strip(chars = {'b', 'a'}) == "laXbl"
    doAssert c.strip(chars = {'b', 'a', 'l'}) == "X"

  var
    first = 0
    last = len(s)-1
  when leading:
    while first <= last and s.runeAtPos(first) in chars: inc(first)
  when trailing:
    while last >= first and s.runeAtPos(last) in chars: dec(last)
  result = s[first .. last]

func strip*(self: PyStr): PyStr = self.strip(true, true)
func lstrip*(self: PyStr): PyStr = self.strip(trailing=false)
func rstrip*(self: PyStr): PyStr = self.strip(leading=false)

converter asSet(s: PyStr): seq[Rune] = s.toRunes
func strip*(self: PyStr,  chars: PyStr): PyStr =
  self.strip(chars=chars.asSet)
func lstrip*(self: PyStr, chars: PyStr): PyStr =
  self.strip(trailing=false, chars=chars.asSet)
func rstrip*(self: PyStr, chars: PyStr): PyStr =
  self.strip(leading=false, chars=chars.asSet)
