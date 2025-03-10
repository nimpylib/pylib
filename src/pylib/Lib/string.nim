
import std/macros
import std/tables
import ../pystring
import ../noneType
import ../builtins/[dict, list]
export pystring, list
import ./collections/abc

import ../version

import ./n_string
import string_impl/[
    templateImpl
]
export Template, delimiter

template expStr(sym) =
  const sym* = str n_string.sym

expStr ascii_lowercase
expStr ascii_uppercase
expStr ascii_letters
expStr digits
expStr hexdigits
expStr octdigits
expStr punctuation
expStr whitespace
expStr printable


genCapwords StringLike, PyStr,
  pystring.split, pystring.split, pystring.capitalize, pystring.strip

proc capwords*(a: StringLike; _: NoneType): PyStr = capwords(a)

proc toTable[K, V](ls: Mapping[K, V]): Table[K, V] =
  ## .. note:: we use `string` as value type internally anyway.
  result = initTable[K, V](ls.len)
  for (k, v) in ls.items():
    result[k] = v

genSubstitute(Mapping, PyStr, substitute,      initRaisesExcHandle)
genSubstitute(Mapping, PyStr, safe_substitute, initIgnoreExcHandle)

proc is_valid*(templ: Template): bool{.pysince(3,11).} =
  templateImpl.is_valid(templ)

proc get_identifiers*(templ: Template): PyList[PyStr]{.pysince(3,11).} =
  result = newPyList[PyStr]()
  for i in get_identifiersMayDup(templ):
    if i not_in result:
      result.append i
