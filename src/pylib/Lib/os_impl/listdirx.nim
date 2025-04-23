
import std/os
import ./common
import ./listcommon

proc listdir*[T](p: PathLike[T] = "."): PyList[T] =
  sys.audit("os.listdir", p)
  result = newPyList[T]()
  p.tryOsOp:
    for i in walkDir($p, relative=true, checkDir=true):
      result.append i.path
