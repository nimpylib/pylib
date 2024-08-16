
# reference source: Modules/posixmodule.c

import std/os

import ./common
import ./posix_like/mkrmdir

when InJs:
  import ./osJsPatch
  proc cwd(): cstring{.importDenoOrProcess(cwd).}
  proc getcwd*(): PyStr = str cwd()
  proc getcwdb*(): PyBytes = bytes cwd()
  proc chdir(d: cstring){.importDenoOrProcess(chdir).}
  proc chdir*(s: PathLike) = chdir cstring $s

else:
  proc getcwd*(): PyStr = str getCurrentDir()
  proc getcwdb*(): PyBytes = bytes getCurrentDir()
  proc chdir*(s: PathLike) = setCurrentDir $s

proc makedirs*[T](d: PathLike[T], mode=0o777, exists_ok=false) =
  let dir = $d
  if dir == "":
    return
  var omitNext = isAbsolute(dir)
  for p in parentDirs(dir, fromRoot=true):
    if omitNext:
      omitNext = false
    else:
      if not exists_ok and dirExists(p):
        raiseFileExistsError mapPathLike[T] p
      mkdir(p)

proc removedirs*(d: PathLike) =
  let dir = $d
  if dir == "":
    return
  # raises OSError if the leaf directory could not be successfully removed.
  rmdir(d)  
  var omitNext = isAbsolute(dir)
  try:
    for p in parentDirs(dir, inclusive=false):
      rmdir(p)
  except OSError:
    discard
