
import std/macros

import ./pysugar/[
  pywith, tonim, class, pydef, unpack
]

export pywith, tonim, class, pydef, unpack

# nimv2 somehow has a bug
# # lib.nim
# template pass* = discard
# template pass*(_) = discard
#
# # main.nim
# import lib
# pass  # <- Error: ambiguous identifier: 'pass' -- ...
template pass*(_) = discard ## suport either `pass 42` or `pass`

template lambda*(code: untyped): untyped =
  (proc (): auto = code)  # Mimic Pythons Lambda

template `:=`*(name, value: untyped): untyped =
  ## Mimic Pythons Operator.
  ## Creates new variable `name` and assign `value` to it.
  (var name = value; name)

macro del*(seqIdx: untyped) =
  ## - `del ls[idx]` -> `delete(ls, idx)`;
  ## - `del obj.attr` -> compilation-error. Nim is static-typed,
  ##  dynamically deleting object's attributes is not allowed.
  ## 
  ## Something like `ls[1:3]` is just disallowed in Nim's syntax.
  ## 
  ## NOTE: Nim's del(seq, idx) is an O(1) operation, 
  ##  which moves the last element to `idx`
  result = newCall(newDotExpr(ident"system", ident"del"), seqIdx)
  var seqV, idx: NimNode
  if seqIdx.kind == nnkBracketExpr:
    # XXX: why this branch is not entered but the next?
    seqV = seqIdx[0]
    idx  = seqIdx[1]
  elif seqIdx.kind == nnkCall:
    if seqIdx[0].repr != "[]":
      return
    seqV = seqIdx[1]
    idx = seqIdx[2]
  else:
    return
  result = newCall("delitem", seqV, idx)
