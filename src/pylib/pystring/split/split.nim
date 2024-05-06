
include ./common
import std/[strutils, unicode]

iterator split*(a: PyStr, maxsplit = -1): PyStr =
  ## with unicode whitespaces as sep.
  ## 
  ## treat runs of whitespaces as one sep (i.e.
  ##   discard empty strings from result),
  ## while Nim's `unicode.split(s)` doesn't
  ##
  ## .. warning:: Currently maxsplit may be wrongly treated
  # the following line is a implementation that only respect ASCII whitespace
  #for i in strutils.split($a): if i != "": yield i
  for i in unicode.split($a, maxsplit=maxsplit):
    if i.len != 0: yield i

iterator split*(a: PyStr,
    sep: StringLike, maxsplit = -1): PyStr{.inline.} =
  noEmptySep sep
  for i in strutils.split($a, $sep, maxsplit): yield i

func split*(a: StringLike, maxsplit = -1): seq[PyStr] =
  for i in split.split(a, maxsplit): result.add i
func split*(a: StringLike, sep: StringLike, maxsplit = -1): seq[PyStr] =
  noEmptySep sep
  for i in split.split(a, sep, maxsplit): result.add i
