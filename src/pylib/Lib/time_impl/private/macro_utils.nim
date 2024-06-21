

import std/macros
import std/strutils


func expectObjectType(n: NimNode) =
  if n.typeKind != ntyObject:
    error "not a object/ref object, cannot extract from a " & $n.typeKind

type
  AttrList = object
    typ: NimTypeKind
    master: NimNode
    data: NimNode

func recListFromObjectType(objTyp: NimNode): NimNode =
  result = objTyp[2]
  expectKind result, nnkRecList

func newAttrList(obj: NimNode): AttrList =
  let base = obj.getType
  let typ = base.typeKind
  result = AttrList(master: obj, typ: typ)
  case typ
  of ntyRef:
    let obj = base[1].getType
    obj.expectObjectType
    result.data = recListFromObjectType obj    
    result.typ = ntyObject
  of ntyObject:
    result.data = recListFromObjectType obj    
  of ntyTuple:
    result.data = base.getTypeImpl
  else:
    doAssert false, "not tuple or ref object or object"

using attrs: AttrList
func len(attrs): int = attrs.data.len

iterator items(attrs): NimNode =
  case attrs.typ
  of ntyObject:
    for i in attrs.data:
      yield newDotExpr(attrs.master, i)
  of ntyTuple:
    for i in 0..<attrs.len:
      yield nnkBracketExpr.newTree(attrs.master, newLit i)
  else: doAssert false; yield newEmptyNode()

func `[]`(attrs; i: int): NimNode =
  case attrs.typ
  of ntyObject:
    newDotExpr(attrs.master, attrs.data[i])
  of ntyTuple:
    nnkBracketExpr.newTree(attrs.master, newLit i)
  else: doAssert false; newEmptyNode()

func getName(attrs; i: int): NimNode =
  assert attrs.typ == ntyObject
  result = attrs.data[i]

func getAttrSym(attrs; i: int): NimNode =
  assert attrs.typ == ntyObject
  result = attrs.data[i]

template getAttrList(objOrType: NimNode): untyped =
  ## returns a argList of nnkSym
  objOrType.newAttrList

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
  
  let
    attrs = obj.getAttrList
    tupLen = tupType.len
    aLen = attrs.len
  if tupLen > aLen:
    error $obj & " takes an at most $#-sequence ($#-sequence given)"
      .format(aLen, tupLen)
  #const BetterTypeMismatchErrMsg = true
  when false: #BetterTypeMismatchErrMsg:
    let namedTuple = tupType.kind == nnkTupleTy
  for i in 0..<tupLen:
    let k = attrs.getName i
    
    when false: #BetterTypeMismatchErrMsg:
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
    let k = attrs.getAttrSym i
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

  let firstK = attrs.getName 0
  addAttrItem firstK
  let le = min(attrs.len, noMoreThan)
  for i in 1..<le:
    addStrNode newLit ", "
    addAttrItem attrs.getName i

type
  CmpStragy* = enum
    csEq
    csLhs
    csRhs
    csShorter  ## stop on the shorter one.

func getEqAttrList(a, b: NimNode): AttrList =
  ## error if a, b attrList is not length equal
  result = a.getAttrList
  if result.len != b.getAttrList.len:
    error "not length equal"
func getShorterAttrList(a, b: NimNode): (AttrList, int) =
  result[0] = a.getAttrList
  let bAttrs = b.getAttrList
  result[1] = result[0].len - bAttrs.len
  if result[1] > 0:
    result[0] = bAttrs

func attrList(a, b: NimNode, stragy: CmpStragy): AttrList = 
  case stragy
  of csLhs: a.getAttrList
  of csRhs: b.getAttrList
  of csEq: getEqAttrList(a, b)
  of csShorter: getShorterAttrList(a, b)[0]

proc orderOnFieldsImpl(a, b: NimNode; cs: CmpStragy = csEq,
    cmpOp=ident"=="): NimNode =
  let attrs = attrList(a, b, cs)
  result = newLit true
  for attr in attrs:
    let
      aVal = attr
      bVal = newDotExpr(b, attr[1])
    let eq = newNimNode(nnkInfix).add(cmpOp, aVal, bVal)
    result = infix(result, "and", eq)

macro mixinOrderOnFields*(
    lhs, rhs: typed;
    cmpOp; cmpStragy: static[CmpStragy] = csEq): bool =
  ## cmpOnFields but `a` `b` can be of different types.
  ## 
  ## e.g. a is tuple and b is object; or a, b are different objects.
  ## 
  orderOnFieldsImpl lhs, rhs, cmpStragy, cmpOp

macro orderOnFields*[T](a, b: T;
    cmpOp): bool =
  ## mainly for checking if ref objects are equal on fields
  ## 
  ## when for object/tuple and cmpOp is `==`, roughly equal to: a == b
  ## 
  ## but system.`==` for ref just compare the address.
  orderOnFieldsImpl a, b, csLhs, cmpOp

proc cmpOnFieldsImpl(a, b: NimNode; cmpOp=ident"cmp"): NimNode =
  let
    aAttr = a.getAttrList
    bAttr = b.getAttrList
    aLen = aAttr.len
    bLen = bAttr.len
    lenDiff = aLen - bLen
    minLen = if lenDiff > 0: bLen else: aLen
  result = newStmtList()
  let res = genSym(nskVar, "cmpRes")
  result.add newVarStmt(res, newLit 0)
  let blkLab = genSym(nskLabel, "blkLab")
  var blkBody = newStmtList()
  let brkBlk = nnkBreakStmt.newTree blkLab
  for i in 0..<minLen:
    let
      aVal = aAttr[i]
      bVal = bAttr[i]
    blkBody.add(
      newAssignment(res, newCall(cmpOp, aVal, bVal)))
    blkBody.add(
      quote do:
        if `res` == 0: `brkBlk`
    )
  result.add newBlockStmt(blkLab, blkBody)
  let lenDiffNode = newLit lenDiff

  let resExpr = quote do:
    if `res` == 0: `lenDiffNode`
    else: `res`

  result.add resExpr

macro cmpOnField*(a, b: typed): int =
  cmpOnFieldsImpl(a, b)
