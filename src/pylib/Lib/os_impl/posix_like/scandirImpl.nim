
import std/os
import ../common
import ./stat

type
  ScandirIterator[T] = ref object
    iter: iterator(): DirEntry[T]
  DirEntry*[T] = ref object
    name*: T
    path*: T
    kind: PathComponent
    stat_res: ref stat_result

func close*(scandirIter: ScandirIterator) = discard
iterator items*[T](scandirIter: ScandirIterator[T]): DirEntry[T] =
  for i in scandirIter.iter:
    yield i

using self: DirEntry

proc newDirEntry[T](name: string, dir: string, kind: PathComponent
): DirEntry[T] =
  new result
  result.name = mapPathLike[T] name
  result.path = mapPathLike[T] joinPath(dir, name)
  result.kind = kind

func repr*(self): string =
  "<DirEntry " & self.name.repr & '>'

template gen_is_x(is_x, pcX, pcLinkToX){.dirty.} =
  func is_x*(self): bool = 
    ## follow_symlinks is True on default.
    self.kind == pcX or self.kind == pcLinkToX
  func is_x*(self; follow_symlinks: bool): bool =
    ## result is cached. Python's is cached too.
    result = self.kind == pcX
    if follow_symlinks:
      return result or self.kind == pcLinkToX
gen_is_x is_file, pcFile, pcLinkToFile
gen_is_x is_dir, pcDir, pcLinkToDir
func is_symlink*(self): bool = 
  ## ..warning:: this may differ Python's
  self.kind == pcLinkToDir or self.kind == pcLinkToFile

func stat*(self): stat_result =
  if self.stat_res != nil:
    return self.stat_res[]
  let path = joinPath(self.dir[], self.name)
  result = stat(path)
  new self.stat_res
  self.stat_res[] = result

template scandirImpl{.dirty.} =
  # NOTE: this variant is referred by ../walkImpl
  let spath = $path
  try:
    for t in walkDir(spath, relative=true, checkDir=true):
      let de = newDirEntry[T](name = t.path, dir = spath, kind = t.kind)
      yield de
  except OSError as e:
    let oserr = e.errorCode.OSErrorCode
    path.raiseExcWithPath(oserr)

iterator scandir*[T](path: PathLike[T]): DirEntry[T] = scandirImpl
iterator scandirIter*[T](path: T): DirEntry[T]{.closure.} =
  ## used by os.walk
  scandirImpl 

iterator scandir*(): DirEntry[PyStr] =
  for de in scandir[PyStr](str('.')):
    yield de

proc scandir*[T](path: PathLike[T]): ScandirIterator[T] =
  new result
  result.iter = iterator(): DirEntry[T] =
    for de in scandir[T](path): yield de

proc scandir*(): ScandirIterator[PyStr] =
  scandir[PyStr](str('.'))
