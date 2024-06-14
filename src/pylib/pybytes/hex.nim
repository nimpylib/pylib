
import ./bytesimpl
import ../pystring/strimpl
import std/strutils

const hexChars = "0123456789abcdef"

template setHex(result; c: char, base: int) =
  var n = ord(c)
  result[base + 1] = hexChars[n and 0xF]
  n = n shr 4
  result[base] = hexChars[n]

func toLowerHex(s: string): string =
  result = newString(s.len * 2)
  for pos, c in s:
    result.setHex c, 2 * pos

func toLowerHex(s: string; sep: char): string =
  let le = s.len
  if le == 0: return ""
  if le == 1: return s.toLowerHex
  result = newString le * 3 - 1
  result.setHex s[0], 0
  for i in 1..<le:
    let pos = 3 * i
    result[pos-1] = sep
    result.setHex s[i], pos

using self: PyBytes
func hex*(self): PyStr =
  # strutils.toHex returns uppercase,
  # but python's bytes.hex returns lowercase.
  str toLowerHex $self


func hex*(self; sep: char): PyStr = str toLowerHex($self, sep)

template chkLen(sep) =
  when not defined(release):
    if sep.len != 1:
      raise newException(ValueError, "sep must be length 1.")
func hex*(self; sep: PyStr|PyBytes): PyStr =
  chkLen sep
  str toLowerHex($self, sep.getChar(0))

func hex*(self; sep: char|PyStr|PyBytes, bytes_per_sep: int): PyStr =
  when sep isnot char:
    chkLen sep
  else:
    let sep = sep.getChar(0)
  var res = toLowerHex($self, sep)
  if bytes_per_sep < 0:
    res.insert sep, res.len + bytes_per_sep
  else:
    res.insert sep, bytes_per_sep
  result = str res

func fromhex*(_: typedesc[PyBytes], s: PyStr): PyBytes =
  ## bytes.fromhex(s)
  ## 
  ## spaces are allowed, unlike Nim's `strutils.parseHexStr`
  var ns = newStringOfCap s.byteLen
  for c in s.chars:
    if c != ' ': ns.add c
  result = bytes parseHexStr ns
