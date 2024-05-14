
import std/os as nos

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
pbExp islink, symlinkExists

fsExp dirname, parentDir

psExp abspath, absolutePath

func samefile*(a, b: PathLike): bool = samefile(a.fspath, b.fspath)

template split2Via(p, fn) =
  let t = fn $p
  result[0] = mapPathLike[T] t[0]
  result[1] = mapPathLike[T] t[1]

func split*[T](p: PathLike[T]): (T, T) = p.split2Via nos.splitPath
func splitdrive*[T](p: PathLike[T]): (T, T) = p.split2Via nos.splitDrive
# Nim's os.splitDrive is adapted from Python's alreadly.

func splitext*[T](p: PathLike[T]): (T, T) =
  let t = p.fspath
  let s = $t
  let idx = s.searchExtPos(s)
  if idx == -1:
    return (t, mapPathLike[T](""))
  result = (
    mapPathLike[T](s[0..<idx]),
    mapPathLike[T](s[idx..^1])
  )

# fsExp expanduser, expandTilde

func join*[T](a, b: PathLike[T]): T =
  result = mapPathLike[T] joinPath($a.fspath, $b.fspath)

# XXX: Cannot be easily impl as varargs[PathLike]
func join*[T](a, b, c: PathLike[T], ps: varargs[PathLike[T]]): T =
  ## ..warning:: NIM-BUG: Currently this variant may fail to compile with
  ## `Error: type mismatch`
  result = mapPathLike[T] joinPath(a.fspath, b.fspath)
  for p in ps:
    result = mapPathLike[T] joinPath(result, p.fspath)
  