
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
