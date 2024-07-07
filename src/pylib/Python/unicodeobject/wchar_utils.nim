
import ../wchar_t as wchar_t_lib
export wchar_t_lib
import std/unicode

using s: ptr wchar_t

proc len*(s): int =
  result = 0
  while s[result] != wchar_t(0): result.inc

proc size*(s): csize_t =
  result = 0
  while s[result] != wchar_t(0): result.inc

iterator items*(s): wchar_t =
  var
    i = 0
    ch = s[i]
  while ch != wchar_t(0):
    yield ch
    i.inc
    ch = s[i]

template dollarImpl =
  result = newStringOfCap le  # maybe shall be more
  for wc in s:
    result.add Rune(wc.ord)
proc `$`*(s; size = s.size): string =
  ## .. warning:: as equal to `s$Natural(size)`
  let le = Natural(size)
  dollarImpl

proc `$`*(s; le: int): string = dollarImpl
