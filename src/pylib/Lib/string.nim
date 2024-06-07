
import ../pystring
import ./collections/abc
from std/strutils import `%`
import std/macros

const
  ascii_lowercase* = str "abcdefghijklmnopqrstuvwxyz"
  ascii_uppercase* = str "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ascii_letters* = ascii_lowercase + ascii_uppercase
  digits* = str "0123456789"
  hexdigits* = str "0123456789abcdefABCDEF"
  octdigits* = str "01234567"
  punctuation* = str """!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~"""
  whitespace* = str " \t\n\r\x0b\x0c"
  printable* = digits + ascii_letters + punctuation + whitespace


func capwords*(a: StringLike): PyStr =
  ## Mimics Python string.capwords(s) -> str:
  ## 
  ## Runs of whitespace characters are replaced by a single space
  ##  and leading and trailing whitespace are removed.
  for word in pystring.split(str(a)):
    result += pystring.capitalize(word)
    result += ' '
  result = pystring.strip(result)

func capwords*(a: StringLike, sep: StringLike): PyStr =
  ## Mimics Python string.capwords(s, sep) -> str:
  ## 
  ## Split the argument into words using split, capitalize each
  ##  word using `capitalize`, and join the capitalized words using
  ##  `join`. `sep` is used to split and join the words.
  let ssep = $sep
  for word in pystring.split(str(a), ssep):
    result += pystring.capitalize(word)
    result += ssep

type Template* = distinct string  ##[
  .. hint:: Currently inhert `Template` is not supported.

  .. warning:: Currently in `substitute`,

  .. warning:: Currently `substitute` is implemented via `%` in std/strutils,
  which will causes two different behaviors from Python's Template:
    1. the variables are compared with `cmpIgnoreStyle`,
   whereas in Python they are just compared 'ignorecase' by default.
    2. digit or `#` following the dollar (e.g. `$1`) is allowed,
     and will be substituted by variable at such position,
     whereas in Python such will cause `ValueError`.
  ]##

func substitute*(templ: Template): PyStr = str templ
macro substitute*(templ: Template, kws: varargs[untyped]): PyStr =
  ## `Template.substitute(**kws)`
  ## 
  var arrNode = newNimNode nnkBracket
  for kw in kws:
    expectKind kw, nnkExprEqExpr
    arrNode.add newLit $kw[0]
    arrNode.add kw[1]
  result = newCall(bindSym("%"), newCall("string", templ), arrNode)
  result = newCall(bindSym"str", result)

macro substitute*(templ: Template, mapping: Mapping, kws: varargs[untyped]): PyStr =
  ## `Template.substitute(mapping, **kws)`
  ## 
  ## where `kws` is preferred if the same key occurs in `mapping`

  # nim's `%` in std/strutils uses first key-value pair found,
  # so put `kws` in the front of seq
  let seqVar = genSym(nskVar, "subsRes")
  let seqDef = if kws.len == 0:
    newNimNode(nnkVarSection).add(
      nnkIdentDefs.newTree(seqVar,
        parseExpr"seq[system.string]", newEmptyNode()))
  else:
    var arrNode = newNimNode nnkBracket  # will be prefixed with `@` to become a seq
    for kw in kws:
      expectKind kw, nnkExprEqExpr
      arrNode.add newLit $kw[0]
      arrNode.add newCall("$", kw[1])
    newVarStmt(seqVar, prefix(arrNode, "@"))
  result = newStmtList()
  result.add seqDef
  let reprId = ident("repr")
  let mappingId = if mapping.kind in {nnkIdent, nnkSym}:
    mapping
  else:
    let mapId = genSym(nskLet, "mappingIdent")
    result.add newLetStmt(mapId, mapping)
    mapId
  result.add quote do:
    for k in `mappingId`.keys():
      add `seqVar`, k.`reprId`
      add `seqVar`, `mappingId`[k].`reprId`
  var res = newCall(bindSym("%"), newCall("string", templ), seqVar)
  res = newCall(bindSym"str", res)
  result.add res

  result = newBlockStmt result  # make sure seq is destoryed
