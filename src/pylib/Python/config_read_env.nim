

import std/os
import std/strutils

using name: string
func toAllUpper(name): string {.inline.} =
  for c in name:
    case c
    of 'a'..'z': result.add chr(ord(c) or 0b100000)
    else: discard # '_' is discarded, so for other chars
func toPyEnv*(name): string {.inline.} = "PYTHON" & name.toAllUpper
proc ib_i*[T](name; flagInit: T): T =
  let v = getEnv(name)
  if v.len == 0: return
  max(flagInit, T(
    try:
      let val = parseInt(v)
      if val < 0: 1 # PYTHONDEBUG=text and PYTHONDEBUG=-2 behave as PYTHONDEBUG=1
      else: val
    except ValueError: 1
  ))
proc ib_e*[T](name; flagInit: T): T = flagInit or T existsEnv name
proc ib_b*(name; flagInit: int): int = min 1, ib_i(name, flagInit)
proc ib_b*(name; flagInit: bool): bool = ib_i(name, flagInit)
