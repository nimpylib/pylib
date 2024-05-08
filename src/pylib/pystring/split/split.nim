
import ./common
import std/[strutils, unicode]
import ./reimporter

import ./split_whitespace


iterator split*(a: PyStr, maxsplit = -1): PyStr =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode.split(s)` doesn't
  ##
  for i in split_whitespace.split_whitespace($a, maxsplit=maxsplit):
    yield i

iterator split*(a: PyStr,
    sep: StringLike, maxsplit = -1): PyStr{.inline.} =
  noEmptySep sep
  for i in strutils.split($a, $sep, maxsplit): yield i

template initRes = 
  result = if maxsplit == -1: newPyList[PyStr]() else: newPyListOfCap[PyStr](maxsplit)
proc split*(a: StringLike, maxsplit = -1): PyList[PyStr] =
  str(a).split_whitespace(maxsplit)

func split*(a: StringLike, sep: StringLike, maxsplit = -1): PyList[PyStr] =
  noEmptySep sep
  initRes
  for i in split.split(a, sep, maxsplit): result.append i
