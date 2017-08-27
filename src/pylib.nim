import strutils, math, sequtils, macros, unicode, tables
export math, tables, strutils
import pylib/[
  class, print, types, ops, string/strops, string/pystring, tonim,
  pyrandom]
export class, print, types, ops, strops, pystring, tonim, pyrandom

type 
  Iterable*[T] = concept x
    for value in x:
      value is T
  
const
  True* = true
  False* = false

converter bool*[T](arg: T): bool = 
  ## Converts argument to boolean
  ## checking python-like truthiness
  # If we have len proc for this object
  when compiles(arg.len):
    arg.len > 0
  # If we can compare if it's not 0
  elif compiles(arg != 0):
    arg != 0
  # If we can compare if it's greater than 0
  elif compiles(arg > 0):
    arg > 0 or arg < 0
  # Initialized variables only
  else:
    not arg.isNil()

converter toStr[T](arg: T): string = $arg

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