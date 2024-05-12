
import std/os
import ../common
import ./stat

type
  ScandirIterator[T] = ref object
    iter: iterator(): DirEntry[T]
  DirEntry*[T] = ref object
    name*: T
    dir: ref string  # over one `scandir`, the dir is just the same
    kind: PathComponent
    stat_res: ref stat_result

func close*(scandirIter: ScandirIterator) = discard
using self: DirEntry

proc newDirEntry[T](name: string, dir: ref string, kind: PathComponent
): DirEntry[T] =
  new result
  result.name =
    when T is PyStr: str(name)
    else: bytes(name)
  result.dir = dir
  result.kind = kind

func repr*(self): string =
  "<DirEntry " & self.name.repr & '>'

template gen_is_x(is_x, pcX, pcLinkToX){.dirty.} =
  func is_x*(self): bool = 
    ## follow_symlinks is True on default.
    self.kind == pcX or self.kind == pcLinkToX
  func is_x*(self; follow_symlinks: bool): bool =
    result = self.kind == pcX
    if follow_symlinks:
      return result or self.kind == pcLinkToX
gen_is_x is_file, pcFile, pcLinkToFile
gen_is_x is_dir, pcDir, pcLinkToDir


func stat*(self): stat_result =
  if self.stat_res != nil:
    return self.stat_res[]
  let path = joinPath(self.dir[], self.name)
  result = stat(path)
  new self.stat_res
  self.stat_res[] = result

iterator scandir*[T](path: PathLike[T]): DirEntry[T]{.closure.} =
  let spath = $path
  if not dirExists spath:
    raiseFileNotFoundError(spath)
  let dir = new string
  dir[] = spath
  for t in walkDir(spath, relative=true):
    let de = newDirEntry[T](name = t.path, dir = dir, kind = t.kind)
    yield de

iterator scandir*(): DirEntry[PyStr]{.closure.} =
  for de in scandir[PyStr](str('.')):
    yield de

proc scandir*[T](path: PathLike[T]): ScandirIterator[T] =
  new result
  result.iter = iterator(): DirEntry[T] =
    for de in scandir[T](path): yield de

proc scandir*(): ScandirIterator[PyStr] =
  scandir[PyStr](str('.'))
