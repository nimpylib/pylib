
import std/os

import ./consts
export consts

# XXX: why cannot as s: PathLike
template templfExp(nam, nimProc, resType){.dirty.} =
  func nam*(s: string): resType = nimProc s

template templpExp(nam, nimProc, resType){.dirty.} =
  proc nam*(s: string): resType = nimProc s

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

# fsExp expanduser, expandTilde

func join*(v: varargs[string]): string = joinPath v
  # XXX: Cannot be easily impl as varargs[PathLike]

