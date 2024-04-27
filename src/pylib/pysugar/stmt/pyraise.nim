## Implement NOTE: We cannot define a macro or function called `raise`,
## as in Nim, `raise`, a keyword, will be parsed as part of `nnkRaiseStmt`.

import std/macros

proc rewriteRaise*(rStmt: NimNode): NimNode =
  ## Rewrites `raise ErrType/ErrType()/ErrType(msg)`
  ## to `raise newException(ErrType, msg/"")`
  ## 
  ## assume `rStmt` is nnkRaiseStmt
  result = rStmt
  var msg = newLit ""
  block rewriteRaise:
    template rewriteWith(err: NimNode){.dirty.} =
      let nExc = newCall("newException", err, msg)
      # User may define some routinues that are used in `raise`,
      result = quote do:
        when compiles(`nExc`):
          raise `nExc`
        else:
          `result`
      
    let raiseCont = rStmt[0]
    case raiseCont.kind
    of nnkCall:
      # raise ErrType[(...)]
      let err = raiseCont[0]
      let contLen = raiseCont.len
      if contLen > 2:
        # cannot be python-like `raise`
        break rewriteRaise
      if contLen == 2:
        # raise ErrType(msg)
        msg = raiseCont[1]
      rewriteWith err
    of nnkIdent:  # raise XxError
      let err = raiseCont
      rewriteWith err  # in case `raise <a Template>`
    else:
    #of nnkEmpty: # leave `raise` as-is
      break rewriteRaise
