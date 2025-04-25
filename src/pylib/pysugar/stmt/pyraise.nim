## Implement NOTE: We cannot define a macro or function called `raise`,
## as in Nim, `raise`, a keyword, will be parsed as part of `nnkRaiseStmt`.

import std/macros

proc add_parent(e: ref Exception; e2: ref Exception): ref Exception =
  result = e
  result.parent = e2

func rewriteRaiseImpl(res: var NimNode, raiseCont: NimNode, parent=newNilLit()): bool =
    var msg = newLit ""
    res = newNimNode nnkWhenStmt
    template callIfValid(chkDest, dest) =
      res.add nnkElifExpr.newTree(
        newCall("compiles", chkDest),
          dest
      )
    template callAddParent(ori) =
      callIfValid(ori,
          newCall(bindSym"add_parent", ori, parent)
      )
    template rewriteWith(err: NimNode){.dirty.} =
      callAddParent(
        newCall("newPy" & err.strVal, msg))
      callAddParent(
        newCall("new" & err.strVal, msg))
      let nExc = newCall("newException", err, msg, parent)
      callIfValid(nExc, nExc)
      res.add(
      # User may define some routinues that are used in `raise`,
        nnkElseExpr.newTree(
          raiseCont
        )
      )
      #[
        when ...
        elif compiles(`nExc`):
          `nExc`
        else:
          `raiseCont`
      ]#
      return true

    case raiseCont.kind
    of nnkCall:
      # raise ErrType([...])
      let err = raiseCont[0]
      let contLen = raiseCont.len
      if contLen > 2:
        # cannot be python-like `raise`
        res = raiseCont
        return true
      if contLen == 2:
        # raise ErrType(msg)
        msg = raiseCont[1]
      rewriteWith err
    of nnkIdent:  # raise XxError
      let err = raiseCont
      rewriteWith err  # in case `raise <a Template>`
    else:
      res = raiseCont
      return

proc rewriteRaise*(rStmt: NimNode): NimNode =
  ## - Rewrites `raise ErrType/ErrType()/ErrType(msg)`
  ##   to `raise newException(ErrType, msg/"")`
  ## - Rewrites `raise XxError[(...)]` to `raise new[Py]XxError(...)`
  ## - Rewrites `raise XxError[(...)] from P` to `raise new[Py]OSError(...).add_parent(P)`
  ## 
  ## assume `rStmt` is nnkRaiseStmt
  var res: NimNode
  block rewriteRaise:
    let raiseCont = rStmt[0]
    let succ = rewriteRaiseImpl(res, raiseCont)
    if succ: break rewriteRaise
    elif raiseCont.kind == nnkInfix and raiseCont[0].eqIdent"from":
      # raise xxx from yyy
      var parent = newNilLit()
      let _ = rewriteRaiseImpl(parent, raiseCont[2])
      let _ = rewriteRaiseImpl(res, raiseCont[1], parent)
    else:
    #of nnkEmpty: # leave `raise` as-is
      #error "only call/ident shall be passed here", raiseCont
      result = rStmt
      return
  result = nnkRaiseStmt.newTree(res)


