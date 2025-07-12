
import std/macros
import std/strformat
import ./formatWithSpec
export formatWithSpec

type GetitemableOfK*[K] = concept self
  self[K]

template `&=`*(result: var NimNode, s: NimNode) =
  bind infix
  result = infix(result, "&", s)

template formatedValue*(v; spec): string =
  var s: string
  s.formatValue v, spec
  s

# NIM-BUG: repr(spec) is (fill: <int>, ..)
#  over StandardFormatSpecifier(fill: char, ...)


proc formatValue*(result: var NimNode, x: NimNode, spec: NimNode) =
  result &= newCall(bindSym"formatedValue", x, spec)
proc formatValue*[T](result: var NimNode, x: int, spec: NimNode) =
  result.formatedValue newLit x, spec


proc add*(result: var NimNode, c: char) =
  result &= newLit c

proc addSubStr*(result: var NimNode, s: NimNode, start, stop: int) =
  result &= (quote do: `s`[`start` ..< `stop`])
proc addSubStr*(result: var NimNode, s: string, start, stop: int) =
  result &= newLit s[start ..< stop]

proc addSubStr*(self: var string, s: openArray[char], start: int, stop: int) =
  ##[ Add a substring to the string.
     `start..<stop`

   roughly equal to self.add s[start ..< stop]
  ]##
  let rng = start ..< stop
  when declared(copyMem):
    let bLen = self.len
    self.setLen bLen + rng.len
    #for i in rng: self[bLen + i] = s[i]
    copyMem(addr(self[bLen]), addr(s[start]), rng.len)
  else:
    for i in rng:
      self.add s[i]
