
import ./common
import std/[strutils, unicode]
import ./reimporter

import ./split_whitespace

import ./splitlinesIter
export splitlinesIter


iterator split*(a: PyStr, sep = None, maxsplit = -1): PyStr =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode.split(s)` doesn't
  ##
  for i in split_whitespace.split_whitespace(a, maxsplit=maxsplit):
    yield i

iterator splitNoCheck(s: string, sep: char|string, maxsplit = -1): PyStr{.inline.} =
  for i in strutils.split(s, sep, maxsplit): yield i
iterator splitNoCheck(s: string, sep: PyStr, maxsplit = -1): PyStr{.inline.} =
  for i in strutils.split(s, $sep, maxsplit): yield i

iterator split*(a: StringLike,
    sep: StringLike, maxsplit = -1): PyStr{.inline.} =
  noEmptySep sep
  for i in splitNoCheck($a, sep, maxsplit): yield i

proc split*(a: StringLike, sep = None, maxsplit = -1): PyList[PyStr] =
  str(a).split_whitespace(maxsplit)

# strutils.split func does not use any predicted capacity.

template initRes(maxcount) = 
  result = newPyListOfCap[PyStr](PREPARE_CAP maxcount)

template byteLen(s: string): int = s.len
template byteLen(c: char): int = 1

proc split*(a: StringLike, sep: StringLike, maxsplit = -1): PyList[PyStr] =
  noEmptySep sep
  # CPython uses unicode len, here using byte-len shall be fine.
  let
    str_len = a.byteLen
    sep_len = sep.byteLen
  initRes norm_maxsplit(maxsplit, str_len=str_len, sep_len=sep_len)
  for i in splitNoCheck($a, sep, maxsplit): result.append i

proc splitlines*(self: PyStr, keepends=false): PyList[PyStr] =

  #[ From split.h splitlines L340
    /* This does not use the preallocated list because splitlines is
       usually run with hundreds of newlines.  The overhead of
       switching between PyList_SET_ITEM and append causes about a
       2-3% slowdown for that common case.  A smarter implementation
       could move the if check out, so the SET_ITEMs are done first
       and the appends only done when the prealloc buffer is full.
       That's too much work for little gain.*/]#
  result = newPyList[PyStr]()
  for i in splitlinesIter.splitlines(self, keepends=keepends):
    result.append i
