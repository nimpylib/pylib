
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

iterator scandir*[T: PathLike](path: T = "."): DirEntry[T]{.closure.} =
  let spath = $path
  if not dirExists spath:
    raiseFileNotFoundError(spath)
  let dir = new string
  dir[] = string path
  for t in walkDir(spath, relative=true):
    let de = DirEntry(name: t.path, dir: dir, kind: t.kind)
    yield de

func scandir*[T: PathLike](path: T = "."): ScandirIterator[T] =
  new result
  result.iter = iterator(): DirEntry[T] =
    for de in scandir(path): yield de
