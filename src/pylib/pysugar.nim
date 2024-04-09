
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

