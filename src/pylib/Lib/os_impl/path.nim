
import std/os

import ./common
export common

import ./consts
export consts

# XXX: why cannot as s: PathLike
template templfExp(nam, nimProc, resType){.dirty.} =
  func nam*(s: PathLike): resType = nimProc s.fspath
template templpExp(nam, nimProc, resType){.dirty.} =
  proc nam*(s: PathLike): resType = nimProc s.fspath

template templfExpRetT(nam, nimProc){.dirty.} =
  func nam*[T](s: PathLike[T]): T = 
    s.mapPathLike nimProc
template templpExpRetT(nam, nimProc){.dirty.} =
  proc nam*[T](s: PathLike[T]): T = 
    s.mapPathLike nimProc

template fbExp(nam, nimProc) =
  templfExp(nam, nimProc, bool)
template pbExp(nam, nimProc){.dirty.} =
  templpExp(nam, nimProc, bool)

template fsExp(nam, nimProc){.dirty.} =
  templfExpRetT(nam, nimProc)
template psExp(nam, nimProc){.dirty.} =
  templpExpRetT(nam, nimProc)

fbExp isabs, isAbsolute
pbExp isfile, fileExists
pbExp isdir, dirExists

fsExp dirname, parentDir

psExp abspath, absolutePath

func samefile*(a, b: PathLike): bool = samefile(a.fspath, b.fspath)

proc split*[T](s: PathLike[T]): (T, T) = splitPath s.fspath

# fsExp expanduser, expandTilde

func join*[T](a, b: PathLike[T]): T =
  result = mapPathLike[T] joinPath(a.fspath, b.fspath)

# XXX: Cannot be easily impl as varargs[PathLike]
func join*[T](a, b, c: PathLike[T], ps: varargs[PathLike[T]]): T =
  ## ..warning:: NIM-BUG: Currently this variant may fail to compile with
  ## `Error: type mismatch`
  result = mapPathLike[T] joinPath(a.fspath, b.fspath)
  for p in ps:
    result = mapPathLike[T] joinPath(result, p.fspath)
  