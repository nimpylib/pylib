
import std/macros
from std/strutils import nimIdentNormalize, toLowerAscii

proc isOfComparisions(op: NimNode): bool =
  ##[ "<" | ">" | "==" | ">=" | "<=" | "!="
                  | "is" ["not"] | ["not"] "in"]##
  if not op.len == 0: return
  let sop = $op
  case sop.len
  of 1:
    sop[0] in {'<', '>'}
  of 2:
    sop in ["==", ">=", "<=", "!="] or
      sop[0] == 'i' and sop[1].toLowerAscii in {'s', 'n'}  # is/in
  else:
    sop.nimIdentNormalize in ["is_not", "not_in"]

proc newInfix(op, l, r: NimNode): NimNode = nnkInfix.newTree(op, l, r)

proc expandChainImpl(resStmt: NimNode, cExp: NimNode): NimNode =
  let
    op = cExp[0]
    lhs = cExp[1]
    rhs = cExp[2]
  template shallChain: bool =
    lhs.len == 3 and op.isOfComparisions and lhs[0].isOfComparisions
  if shallChain:
    let med = lhs[2]
    if med.len != 0:
      let id = genSym(nskLet, "cmpMed")
      resStmt.add newLetStmt(id, med)
      lhs[2] = id
    nnkInfix.newTree(bindSym"and",
      expandChainImpl(resStmt, lhs),
      newInfix(op, lhs[2], rhs))
  else:  # if isCmpOp: # but lhs is not
    cExp

proc expandChainImpl*(cExp: NimNode): NimNode =
  result = newStmtList()
  result.add expandChainImpl(result, cExp)

macro expandChain*(cExp): bool =
  expectKind cExp, nnkInfix
  expandChainImpl(cExp)

when isMainModule:
  template tCmp(m) =
    assert expandChain(1 < m <= 3)
    assert expandChain(1 < m > 2)
  tCmp 3
  var g = 0
  proc f(): int =
    g.inc
    3
  tCmp f()
  assert g == 2, $g
