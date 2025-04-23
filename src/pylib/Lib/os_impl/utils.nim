
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
  proc chdirImpl(s: PathLike) = chdir cstring $s

else:
  proc getcwd*(): PyStr = str getCurrentDir()
  proc getcwdb*(): PyBytes = bytes getCurrentDir()
  proc chdirImpl(s: PathLike) = setCurrentDir $s

proc chdir*(s: PathLike) =
  sys.audit("os.chdir", s)
  chdirImpl(s)

proc makedirs*[T](d: PathLike[T], mode=0o777, exists_ok=false) =
  let dir = $d
  if dir == "":
    return
  var omitNext = isAbsolute(dir)
  for p in parentDirs(dir, fromRoot=true):
    if omitNext:
      omitNext = false
    else:
      p.tryOsOp not exists_ok or not dirExists(p):
        mkdir(p, mode)

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
