
from std/strformat import fmt
import std/macros 

template f*(pattern: static[string]): untyped =
  ## An alias for ``fmt``. Mimics Python F-String.
  ## .. warning:: Currently f"xxx" is the same as fr"xxx"
  # TODO: impl via something like translate-escape
  
  bind `fmt`
  fmt(pattern)
  
template genFR(sym){.dirty.} =
  macro sym*(pattern: static[string]): string = quote do: f`pattern`

genFR fr 
genFR Fr 
genFR rf 
genFR Rf

template u*(a: string): string = a
template u*(a: char): string = $a
template b*(a: string): string = a
template b*(a: char): string = $a
