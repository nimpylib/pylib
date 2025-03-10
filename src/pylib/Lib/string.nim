
import std/macros
import std/tables
import ../pystring
import ../builtins/dict
import ./collections/abc

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

proc toTable[K, V](ls: Mapping[K, V]): Table[K, V] =
  ## .. note:: we use `string` as value type internally anyway.
  result = initTable[K, V](ls.len)
  for (k, v) in ls.items():
    result[k] = $v

genSubstitute(Mapping, PyStr, substitute, raiseKeyError, invalidFormatString)
genSubstitute(Mapping, PyStr, safe_substitute, noraiseKeyError, supressInvalidFormatString)

