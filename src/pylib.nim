import strutils, math, sequtils, macros, unicode, tables
export math, tables, strutils
import pylib/[class, print, types, ops]
export class, print, types, ops

type 
  Iterable*[T] = concept x
    for value in x:
      value is T
  
const
  True* = true
  False* = false

proc input*(prompt = ""): string = 
  ## Python-like input procedure
  if prompt.len > 0:
    stdout.write(prompt)
  stdin.readLine()

proc all*[T](iter: Iterable[T]): bool = 
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

proc any*[T](iter: Iterable[T]): bool = 
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true