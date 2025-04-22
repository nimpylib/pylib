
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

template genToTab(M){.dirty.} =
  proc toTable[K, V](ls: M[K, V]): Table[K, V] =
    ## .. note:: we use `string` as value type internally anyway.
    result = initTable[K, V](ls.len)
    for (k, v) in ls.items():
      result[k] = v

when not defined(js):
  genToTab Mapping
else:
  #[ XXX: NIM-BUG: Error: internal error: genTypeInfo(tyInferred)
  compiler/jstypes.nim(135) genTypeInfo 
  context:
    p.prc.name.s = toTable
    typ[i] = PyStr
  ]#
  genToTab PyDict

genSubstitute(Mapping, PyStr, substitute,      initRaisesExcHandle)
genSubstitute(Mapping, PyStr, safe_substitute, initIgnoreExcHandle)

wrapExportSincePy(3,11, is_valid)

proc get_identifiers*(templ: Template): PyList[PyStr]{.pysince(3,11).} =
  result = newPyList[PyStr]()
  for i in get_identifiersMayDup(templ):
    if i not_in result:
      result.append i
