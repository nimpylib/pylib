
import std/macros

import ./pywith, ./classdef/class, ./classdef/pydef
export class, pydef, pywith

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

macro del*(seqIdx) =
  ## - `del ls[idx]` -> `delete(ls, idx)`;
  ## - `del obj.attr` -> compilation-error. Nim is static-typed,
  ##  dynamically deleting object's attributes is not allowed.
  ## 
  ## NOTE: Nim's del(seq, idx) is an O(1) operation, 
  ##  which moves the last element to `idx`
  runnableExamples:
    var ls = list([1,2,3,4,5])
    del ls[2]
    assert ls[2] == 4
  if seqIdx.kind == nnkBracketExpr:
    let
      seqV = seqIdx[0]
      idx  = seqIdx[1]
    result = newCall("delete", seqV, idx)
  # Maybe others will impl it.
  #elif seqIdx.kind == nnkDotExpr: error "del obj.attr is unsupported in Nim"
  else:
    # fallback AS-IS
    result = newCall("del", seqIdx)
