
import ./common
import std/strutils
import ./reimporter

import ./rsplit_whitespace


iterator rsplit*(a: PyStr, sep = None, maxsplit = -1): PyStr =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode` doesn't has `rsplit` yet
  ##
  for i in rsplit_whitespace.rsplit_whitespace(a, maxsplit=maxsplit):
    yield i

iterator rsplitNoCheck(s: string, sep: char|string, maxsplit = -1): PyStr{.inline.} =
  ## in reversed order
  for i in strutils.rsplit(s, sep, maxsplit): yield i
iterator rsplitNoCheck(s: string, sep: PyStr, maxsplit = -1): PyStr{.inline.} =
  ## in reversed order
  for i in strutils.rsplit(s, $sep, maxsplit): yield i

proc rsplit*(a: PyStr, sep = None, maxsplit = -1): PyList[PyStr] =
  a.rsplit_whitespace(maxsplit)

# strutils.rsplit func does not use any predicted capacity.

template initRes(maxcount) = 
  result = newPyListOfCap[PyStr](PREPARE_CAP maxcount)

template byteLen(s: string): int = s.len
template byteLen(c: char): int = 1

proc rsplit*(a: PyStr, sep: StringLike, maxsplit = -1): PyList[PyStr] =
  noEmptySep sep
  # CPython uses unicode len, here using byte-len shall be fine.
  let
    str_len = a.byteLen
    sep_len = sep.byteLen
  initRes norm_maxsplit(maxsplit, str_len=str_len, sep_len=sep_len)
  for i in rsplitNoCheck($a, sep, maxsplit): result.append i
  result.reverse()
