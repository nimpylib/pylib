

import std/macros
import std/strutils

const BetterTypeMismatchErrMsg = true

func extractObjectType(objOrType: NimNode): NimNode =
  ## extract `object` type from `object` or `ref object` or a instance.
  let base = objOrType.getType
  result = if base.typeKind == ntyRef: base[1].getType
           else: base
  if result.typeKind != ntyObject:
    error "not a object/ref object, cannot extract from a " & $result.typeKind,
      objOrType

template getAttrListFromType(typ: NimNode): NimNode =
  ## returns a argList of nnkSym
  expectKind typ[2], nnkRecList
  typ[2]

template getAttrList(objOrType: NimNode): NimNode =
  ## returns a argList of nnkSym
  objOrType.extractObjectType.getAttrListFromType

macro asgSeqToObj*(tup, obj: typed) =
  ## `obj` can be of `ref object` or `object`
  ## Retionale: there is fields/fieldPairs iterator in std/system,
  ## but for tuple/object only, not for ref object.
  result = newStmtList()
  var tupId: NimNode
  if tup.kind != nnkSym:
    tupId = genSym(nskLet, "tup")
    result.add newLetStmt(tupId, tup)
  else:
    tupId = tup
  
  let tupType = tup.getTypeImpl
  
  when BetterTypeMismatchErrMsg:
    let namedTuple = tupType.kind == nnkTupleTy
  
  let
    attrs = obj.getAttrList
    tupLen = tupType.len
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

func getTypeFromTypeDescNode(n: NimNode): NimNode =
  if n.typeKind != ntyTypeDesc:
    error "not a typedesc", n
  n.getType[1]

macro declTupleWithNFieldsFrom*(name: untyped; Cls: typedesc; n: static[int], exported: static[bool] = true) =
  let
    typ = Cls.getTypeFromTypeDescNode
    attrs = typ.getAttrList
  
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


macro addFields*(res: string, obj: typed, noMoreThan: static[int] = int.high) =
  ## `obj` is of `object` or `ref object`.
  ## when `obj` is of `object` and `noMoreThan` is not given, it's roughly equal to:
  ## 
  ## ```Nim
  ## let startLen = res.len
  ## for k, v in o.fieldPairs:
  ##   res.addSep(sep=", ", startLen = startLen)
  ##   res.add k & '=' & repr v
  ## ```
  
  let attrs = obj.getAttrList
  
  result = newStmtList()
  
  template addStrNode(item) =
    result.add newCall(
      "add", res, item)
  template addAttrItem(attr) =
    let item = newLit($attr & '=')
    addStrNode item
    addStrNode newCall("repr",
      newDotExpr(obj, attr)
    )

  let firstK = attrs[0]
  addAttrItem firstK
  let le = min(attrs.len, noMoreThan)
  for i in 1..<le:
    addStrNode newLit ", "
    addAttrItem attrs[i]

type
  CmpStragy* = enum
    csEq
    csLhs
    csRhs

func getEqAttrList(a, b: NimNode): NimNode =
  ## error if a, b attrList is not length equal
  result = a.getAttrList
  if result.len != b.getAttrList.len:
    error "not length equal"

proc cmpOnFieldsImpl(a, b: NimNode; cs: CmpStragy = csEq,
    cmpOp=ident"=="): NimNode =
  result = newLit true
  let attrs = case cs
    of csLhs: a.getAttrList
    of csRhs: b.getAttrList
    of csEq: getEqAttrList(a, b)
  for attr in attrs:
    let
      aVal = newDotExpr(a, attr)
      bVal = newDotExpr(b, attr)
    let eq = newNimNode(nnkInfix).add(cmpOp, aVal, bVal)
    result = infix(result, "and", eq)

macro mixinCmpOnFields*(
    lhs, rhs: typed;
    cmpOp; cmpStragy: static[CmpStragy] = csEq): bool =
  ## cmpOnFields but `a` `b` can be of different types.
  ## 
  ## e.g. a is tuple and b is object; or a, b are different objects.
  ## 
  ## The order matters, if not `checkEqLen`, compare stops once all fields
  ## of `lhs` is compared. a.k.a. `len(lhs) <= len(rhs)` shall be always true,
  ## where `len` means the number of the fields.
  ## 
  cmpOnFieldsImpl lhs, lhs, cmpStragy, cmpOp

macro cmpOnFields*[T](a, b: T;
    cmpOp): bool =
  ## mainly for checking if ref objects are equal on fields
  ## 
  ## when for object/tuple, roughly equal to: a == b
  ## 
  ## but system.`==` for ref just compare the address.
  cmpOnFieldsImpl a, b, csLhs, cmpOp