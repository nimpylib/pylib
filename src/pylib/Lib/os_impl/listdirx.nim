
import std/os
import ./common
import ./listcommon

proc listdir*[T](p: PathLike[T] = "."): PyList[T] =
  result = newPyList[T]()
  if not dirExists $p:
    raiseFileNotFoundError p
  # NotADirectoryError 
  for i in walkDir($p, relative=true):
    result.append i.path

