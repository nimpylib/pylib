

import std/macros
import std/strutils

const BetterTypeMismatchErrMsg = true

func extractClsObj(obj: NimNode) :NimNode =
  let base = obj.getType
  result = if base.typeKind == ntyRef: base[1].getType
           else: base

template getAttrList(typ: NimNode): NimNode =
  expectKind typ[2], nnkRecList
  typ[2]

macro asgSeqToObj*(tup, obj: typed) =
  result = newStmtList()
  var tupId: NimNode
  if tup.kind != nnkSym:
    tupId = genSym(nskLet, "tup")
    result.add newLetStmt(tupId, tup)
  else:
    tupId = tup
  
  let typ = extractClsObj obj
  
  let tupType = tup.getTypeImpl
  
  when BetterTypeMismatchErrMsg:
    let namedTuple = tupType.kind == nnkTupleTy
  
  let
    tupLen = tupType.len
    attrs = typ.getAttrList
    aLen = attrs.len
  if tupLen > aLen:
    error $obj & " takes an at most $#-sequence ($#-sequence given)"
      .format(aLen, tupLen)
  for i in 0..<tupLen:
    let k = attrs[i]
    
    when BetterTypeMismatchErrMsg:
      let tupItem = tupType[i]
      let tupItemType =
        if namedTuple: tupItem[1]
        else: tupItem
      if tupItemType.typeKind != k.getType.typeKind:
        error ("type mismatch, cannot set $#.$#" &
            " with a '$#'").format(obj.repr, k.repr, tupItemType.repr)
    
    result.add newAssignment(
      obj.newDotExpr(k),
      nnkBracketExpr.newTree(tupId, newLit i)
    )

macro declTupleWithNFieldsFrom*(name: untyped; Cls: typedesc; n: static[int], exported: static[bool] = true) =
  let typedescNode = Cls.getType
  
  let
    typ = typedescNode[1]
    clsType = typ.extractClsObj
    attrs = clsType.getAttrList
  
  var tupleAttrs = newNimNode nnkTupleTy
  for i in 0..<n:
    let k = attrs[i]
    tupleAttrs.add newIdentDefs(
      k, k.getTypeImpl
    )
  var nameId = name
  if exported: nameId = postfix(nameId, "*")
  result = nnkTypeSection.newTree(nnkTypeDef.newTree(
    nameId,
    newEmptyNode(),
    tupleAttrs
  ))

