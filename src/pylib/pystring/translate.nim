## str.translate
## 
## ------
## 
## NOTE: Nim's KeyError is a subclass of ValueError instead of LookupError.
## Therefore when writing a custom `<TranslateTableABC>`_ or `<TypedTranslateTableABC>`_
## for `<translate>`_, beware a Nim's KeyError is not considered
## as a sign to leave such a character untouched, but will be just raised outside.
## 
## However, `<TranslateTable>`_ or `<StrTypedTranslateTable>`_ is handled via overload.
## Using them as translate table is fine.
## 

import ./strimpl
import ./strbltins
import ../noneType
import ../pyerrors/lkuperr
import ../collections_abc
import std/tables
import std/macros

export strimpl, noneType  # for runnableExample

type
  TranslateValType* = int|PyStr|char|NoneType
  TranslateAction*{.pure.} = enum
    skip, aOrd, aChr, aStr
  TranslateTableVal* = object
    case action: TranslateAction
    of skip: discard
    of aOrd: i*: int
    of aChr: c*: char
    of aStr: s*: PyStr
  TranslateTableABC* = concept self
    self[int] is TranslateTableVal
  TypedTranslateTableABC*[V] = concept self
    V  # NIM-BUG
    self[int] is V
  
  TranslateTable* = TableRef[int, TranslateTableVal]  ## result of maketrans
  StrTypedTranslateTable* = TableRef[int, PyStr]  ##[
    result of `str.maketrans(keys, values)<#maketrans,typedesc[PyStr],,>`_
    ]##

static: assert StrTypedTranslateTable is TypedTranslateTableABC[PyStr]

export tables.`[]`, tables.len


template newTranslateTable(cap: int): TranslateTable =
  newTable[int, TranslateTableVal](cap)

func repr*(table: TranslateTable): string =
  ## dict stringification.
  let le = table.len
  result = newStringOfCap le * 5
  result.add "{"
  var i = 0
  for k, v in table.pairs():
    result.add k.repr
    result.add ": "
    result.add case v.action
    of skip: "None"
    of aChr: $v.c
    of aStr: repr v.s
    of aOrd: $v.i
    i.inc
    if i != le:
      result.add ", "
  result.add "}"
template `$`*(table: TranslateTable): string =
  ## repr table
  bind repr
  repr table

template newStrTypedTranslateTable(cap: int): StrTypedTranslateTable =
  newTable[int, PyStr](cap)

func addVal(s: var PyStr, val: TranslateTableVal) =
  case val.action
  of skip: discard
  of aOrd: s += strbltins.chr(val.i)
  of aChr: s += val.c
  of aStr: s += val.s

template addValue[K: TranslateValType](s: var PyStr, value: K) =
  when K is NoneType: discard
  elif K is int:
    s += strbltins.chr(value)
  else:
    s += value

proc translate*(s: PyStr, table: TranslateTable): PyStr =
  for uni in s:
    let o = ord(uni)
    if o in table:
      result.addVal table[o]
    else:
      result += uni

proc translate*(s: PyStr, table: StrTypedTranslateTable): PyStr =
  for uni in s:
    result += table.getOrDefault(ord(uni), uni)

proc translate*[K: TranslateValType](
    s: PyStr, table: TypedTranslateTableABC[K]): PyStr =
  for uni in s:
    try:
      result.addValue table[ord(uni)]
    except LookupError:
      result += uni

proc translate*(s: PyStr, table: TranslateTableABC): PyStr =
  for uni in s:
    try:
      let nval = table[ord(uni)]
      result.addVal nval
    except LookupError:
      result += uni

template initVal: untyped =
  TranslateTableVal(action: TranslateAction.skip)
template initVal(act, attr, v): untyped =
  TranslateTableVal(action: TranslateAction.act, attr: v)

template initValWithV(v; V: typedesc): untyped = 
  when V is NoneType:
    initVal()
  elif V is int:
    initVal(aOrd, i, v)
  elif V is char:
    initVal(aChr, c, v)
  elif V is PyStr:
    initVal(aStr, s, v)
  elif V is string:
    initVal(aStr, s, str v)
  else:
    {.error: "initValWithV with invalid type".}

func maketransWithMapping[K: PyStr|int|char, V: TranslateValType](
    map: Mapping[K, V]): TranslateTable =
  result = newTranslateTable len(map)
  for k, v in map.items():
    let val = initValWithV(v, V)
    template normK =
      when K is int: k
      else: ord(k)
    result[normK] = val

proc TranslateTableFromDictLit(lit: NimNode): NimNode =
  ## {1: 2, ...} -> ```
  ## var <resId> = newTranslateTable(<len>)
  ## <resId>[<normKey>] = <normVal>
  ## ...
  ## <resId>
  ## ```
  expectKind lit, nnkTableConstr
  result = newStmtList()
  let resId = genSym(nskVar, "transTable")
  result.add newVarStmt(resId, 
    newCall(
      bindSym"newTranslateTable",
      newLit lit.len
    )
  )
  let tabSetitem = bindSym"[]="
  template setitem(k, v) =
    result.add newCall(tabSetitem, resId, k, v)
  let initVId = bindSym"initValWithV"
  let ordId = bindSym"ord"
  for item in lit:
    var nitem = item
    if item.kind == nnkHiddenSubConv:
      # HiddenSubConv Empty <nitem>
      expectKind item[0], nnkEmpty
      nitem = item[1]
    expectKind nitem, nnkExprColonExpr
    let (key, val) = (nitem[0], nitem[1])
    var normKey: NimNode
    if key.kind in {nnkStrLit, nnkCharLit}:
      normKey = newCall(ordId, key)
    else:
      if key.kind in nnkCallKinds:
        warning "Currently only literal for key is fully supported", key
      normKey = key
    let normVal = newCall(initVId, val, newCall("typeof", val))
    setitem normKey, normVal
  result.add resId

macro maketrans*(_: typedesc[PyStr], mapOrLit: untyped): TranslateTable =
  ## str.maketrans with dict literal or a mapping
  runnableExamples:
    let tbl = PyStr.maketrans({"a": None, "b": "123"})
    assert "axb".translate(tbl) == "x123"
  if mapOrLit.kind in {nnkTableConstr, nnkBracket}:
    let table = TranslateTableFromDictLit mapOrLit
    result = table
  else:
    result = newCall(bindSym"maketransWithMapping", mapOrLit)

template maketrans*(_: typedesc[PyStr], frm, to): StrTypedTranslateTable =
  ## `frm`, `to` shall be string/PyStr.
  ## 
  ## see `Nim#23662<https://github.com/nim-lang/Nim/issues/23662>`_
  ## for why this is not defined as a proc with typed param-types
  bind newStrTypedTranslateTable, ord, len
  let le = frm.len
  assert le == to.len
  var result = newStrTypedTranslateTable(le)
  for i, uni in frm:
    result[ord(uni)] = to[i]
  result

template maketrans*(_: typedesc[PyStr], frm, to, skip): TranslateTable =
  ## `frm`, `to`, `skip` shall be string/PyStr.
  ##
  ## see `Nim#23662<https://github.com/nim-lang/Nim/issues/23662>`_
  ## for why this is not defined as a proc with typed param-types
  bind newTranslateTable, initVal, ord, len
  let le = frm.len
  assert le == to.len
  var result = newTranslateTable(le)
  for i, uni in frm:
    result[ord(uni)] = initVal(aStr, s, to[i])
  for uni in skip:
    result[ord(uni)] = initVal()
  result
