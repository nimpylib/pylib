
import std/unicode except strip
import ../../pystring/consts

func stripAsRange*(s: openArray[char],
            leading: static[bool] = true,
            trailing: static[bool] = true,
            runes: openArray[Rune] = unicodeSpaces): tuple[first, last: int] =
  ## `s[first..last]` will be stripped data.
  var
    sI = 0      ## starting index into string ``s``
    eI = s.high ## ending index into ``s``, where the last ``Rune`` starts
  var
    i, xI: int ## value of ``sI`` at the beginning of the iteration
    rune: Rune
  when leading:
    while i < len(s):
      xI = i
      fastRuneAt(s, i, rune)
      sI = i # Assume to start from next rune
      if not runes.contains(rune):
        sI = xI # Go back to where the current rune starts
        break
  when trailing:
    i = eI
    while i >= 0:
      xI = i
      fastRuneAt(s, xI, rune)
      var yI = i - 1
      while yI >= 0:
        var
          yIend = yI
          pRune: Rune
        fastRuneAt(s, yIend, pRune)
        if yIend < xI: break
        i = yI
        rune = pRune
        dec(yI)
      if not runes.contains(rune):
        eI = xI - 1
        break
      dec(i)
  (sI, eI)
