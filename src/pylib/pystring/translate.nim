## str.translate

import ./strimpl
import ./strbltins
import ../noneType
import ../pyerrors/lkuperr
import ../collections_abc
import std/tables

type
  TranslateValType* = int|PyStr|char|NoneType
  TranslateAction*{.pure.} = enum
    skip, aOrd, aChr, aStr
  TranslateTableVal* = object
    case action: TranslateAction
    of skip: discard
    of aOrd: i: int
    of aChr: c: char
    of aStr: s: PyStr
  TranslateTableABC* = concept self
    self[int] is TranslateTableVal
  TypedTranslateTableABC*[V] = concept self
    self[int] is V
  
  TranslateTable* = TableRef[int, TranslateTableVal]
  StrTypedTranslateTable* = TableRef[int, PyStr]

static: assert StrTypedTranslateTable is TypedTranslateTableABC[PyStr]

template newTranslateTable(cap: int): TranslateTable =
  newTable[int, TranslateTableVal](cap)

template newStrTypedTranslateTable(cap: int): StrTypedTranslateTable =
  newTable[int, PyStr](cap)

func translate*[K: TranslateValType](
    s: PyStr, table: TypedTranslateTableABC[K]): PyStr =
  for uni in s:
    try:
      let nval = table[ord(uni)]
      when K is NoneType:
        continue
      elif K is int:
        result += strbltins.chr(nval)
      else:
        result += nval
    except LookupError:
      result += uni

func translate*(s: PyStr, table: TranslateTableABC): PyStr =
  for uni in s:
    try:
      let nval = table[ord(uni)]
      case nval.action
      of skip: continue
      of aOrd: result += strbltins.chr(nval.i)
      of aChr: result += nval.c
      of aStr: result += nval.s
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

func maketrans*[K: PyStr|int|char, V: TranslateValType](
    s: typedesc[PyStr], map: Mapping[K, V]): TranslateTable =
  result = newTranslateTable len(map)
  for k, v in map.items():
    let val = initValWithV(v, V)
    template normK =
      when K is int: k
      else: ord(k)
    result[normK] = val

func maketrans*(s: typedesc[PyStr], frm, to: PyStr): StrTypedTranslateTable =
  let le = frm.len
  assert le == to.len
  result = newStrTypedTranslateTable(le)
  for i, uni in frm:
    result[ord(uni)] = to[i]

func maketrans*(s: typedesc[PyStr], frm, to, skip: PyStr): TranslateTable =
  let le = frm.len
  assert le == to.len
  result = newTranslateTable(le)
  for i, uni in frm:
    result[ord(uni)] = initVal(aStr, s, to[i])
  for uni in skip:
    result[ord(uni)] = initVal()
