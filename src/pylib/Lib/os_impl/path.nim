
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

template fbExp(nam, nimProc) =
  templfExp(nam, nimProc, bool)
template pbExp(nam, nimProc){.dirty.} =
  templpExp(nam, nimProc, bool)

template fsExp(nam, nimProc){.dirty.} =
  templfExp(nam, nimProc, string)
template psExp(nam, nimProc){.dirty.} =
  templpExp(nam, nimProc, string)

fbExp isabc, isAbsolute
pbExp isfile, fileExists
pbExp isdir, dirExists

fsExp dirname, parentDir

psExp abspath, absolutePath

func samefile*(a, b: PathLike): bool = samefile(a.fspath, b.fspath)

proc split*(s: PathLike): (string, string) = splitPath s.fspath

# fsExp expanduser, expandTilde

func join*(a: PathLike, v: varargs[PathLike]): string =
  runnableExamples:
    from std/os import joinPath
    assert join("12", "ab") == joinPath("12", "ab")
  result = a.fspath
  for p in v:
    result = joinPath(result, p.fspath)
  # XXX: Cannot be easily impl as varargs[PathLike]

