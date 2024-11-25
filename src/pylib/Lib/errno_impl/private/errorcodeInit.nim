

import ./errnos
import ./loopErrno
export errnos

import std/enumutils
import std/macros

macro initErrorcodeMap*(K, V; res: untyped, initFunc: typed) =
  mixin `[]=`
  result = newStmtList()
  let N = newLit ErrnoCount
  result.add quote do:
    var `res` = `initFunc`[`K`, `V`](`N`)
  forErrno e:
    let
      errName = symbolName e
      errNameNode = newLit errName
      errId = ident errName
    result.add quote do:
      `res`[`errId`] = `errNameNode`

template declErrorcodeWith*[K, V](initFunc: typed) = initErrorcodeMap K, V,errorcode, initFunc
