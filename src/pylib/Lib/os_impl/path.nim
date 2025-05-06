
import std/os as nos
import std/times as ntimes
import std/macros
import ./posix_like/stat

import ./common
export common
when InJs:
  import ./osJsPatch

import ./consts
export consts

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

fsExp basename, extractFilename  # instead of lastPathPart

psExp abspath, absolutePath
psExp normpath, normalizedPath

func relpath*[T](p: PathLike[T], start=curdir): T =
  mapPathLike[T] relativePath($p, $start)

when InJS:
  export getatime, getmtime, getctime
else:
  template expFRetTAsF(nam, nimProc){.dirty.} =
    ## returns Time as float
    proc nam*[T](p: PathLike[T]): float =
      p.tryOsOp: result = nimProc($p).toUnixFloat
  expFRetTAsF getctime, getCreationTime
  expFRetTAsF getmtime, getLastModificationTime
  expFRetTAsF getatime, getLastAccessTime

proc getsize*[T](filename: PathLike[T]): int =
  # std/os.`getFileSize` doesn't work for directory
  int statAttr(filename, st_size)

func samefile*(a, b: PathLike): bool =
  tryOsOp(a, b): result = samefile(a.fspath, b.fspath)

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

template joinImpl[T](a, b: T): T = mapPathLike[T] joinPath($a.fspath, $b.fspath)

proc nestListWithFirst*(op: NimNode; pack: NimNode; first: NimNode): NimNode =
  ## `[a, b, c]` is transformed into `op(first, op(a, op(c, d)))`.
  ## note this differs macros.nestList
  if pack.len == 0:
    return first
  result = pack[^1]
  for i in countdown(pack.len - 2, 0):
    result = newCall(op, pack[i], result)
  result = newCall(op, first, result)

# XXX: Cannot be easily impl as varargs[PathLike]
macro join*[T](a: PathLike[T], ps: varargs[PathLike[T]]): T =
  ## ..warning:: NIM-BUG: Currently this variant may fail to compile with
  ## `Error: type mismatch`
  nestListWithFirst(bindSym"joinImpl", ps, a)

macro join*[T: PyStr|PyBytes](a: T, ps: varargs[T]): T =
  nestListWithFirst(bindSym"joinImpl", ps, a)

proc samestat*(s1, s2: stat_result): bool =
   return (s1.st_ino == s2.st_ino and
            s1.st_dev == s2.st_dev)
