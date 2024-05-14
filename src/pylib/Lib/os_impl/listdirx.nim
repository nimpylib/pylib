
import std/os
import ./common
import ./listcommon

proc listdir*[T](p: PathLike[T] = "."): PyList[T] =
  result = newPyList[T]()
  try:
    for i in walkDir($p, relative=true, checkDir=true):
      result.append i.path
  except OSError as e:
    let oserr = e.errorCode.OSErrorCode
    p.raiseExcWithPath(oserr)
