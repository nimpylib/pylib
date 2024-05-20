
import std/os as nos
import std/times as ntimes

import ./common
export common

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

template expFRetTAsF(nam, nimProc){.dirty.} =
  ## returns Time as float
  proc nam*[T](p: PathLike[T]): float =
    p.tryOsOp: result = nimProc($p).toUnixFloat
expFRetTAsF getctime, getCreationTime
expFRetTAsF getmtime, getLastModificationTime
expFRetTAsF getatime, getLastAccessTime

func getsize*[T](filename: PathLike[T]): int =
  var f: File = nil
  try:
    f = system.open($filename)
    result = getFileSize(f)
  except OSError as e:
    filename.raiseExcWithPath(e.errorCode.OSErrorCode)
  finally:
    f.close()  # syncio.close will do nothing if File is nil

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
  