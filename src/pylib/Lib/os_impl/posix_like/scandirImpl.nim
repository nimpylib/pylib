
import std/os
import ../common
import ./stat

when InJs:
  import std/jsffi
  import ./links
  type
    Dir = JsObject  ## fs.Dir
    Dirent = JsObject  ## fs.Dirent
  from ./jsStat import Stat, statSync
elif defined(posix):
  import ./links
when declared(readlink):
  func func_readlink(x: string): string =
    {.noSideEffect.}:
      result = readlink(x)

type
  DirEntryImpl[T] = ref object of RootObj
    name*: T
    path*: T
    stat_res: ref stat_result

when InJs:
  type HasIsX = JsObject
  template impIsX(isX){.dirty.} =
    func isX(self: HasIsX): bool{.importcpp.}
  impIsX isFile
  impIsX isDirectory
  impIsX isSymbolicLink
  type DirEntry*[T] = ref object of DirEntryImpl[T]
    statObj: HasIsX
else:
  type DirEntry*[T] = ref object of DirEntryImpl[T]
    kind: PathComponent

type ScandirIterator[T] = ref object
    iter: iterator(): DirEntry[T]

func close*(scandirIter: ScandirIterator) = discard
iterator items*[T](scandirIter: ScandirIterator[T]): DirEntry[T] =
  for i in scandirIter.iter:
    yield i

using self: DirEntry

when InJs:
  proc newDirEntry[T](name: string, dir: string, hasIsFileDir: JsObject
  ): DirEntry[T] =
    new result
    result.name = mapPathLike[T] name
    result.path = mapPathLike[T] joinPath(dir, name)
    result.statObj = hasIsFileDir
else:
  proc newDirEntry[T](name: string, dir: string, kind: PathComponent
  ): DirEntry[T] =
    new result
    result.name = mapPathLike[T] name
    result.path = mapPathLike[T] joinPath(dir, name)
    result.kind = kind

func repr*(self): string =
  "<DirEntry " & self.name.repr & '>'

func stat*(self): stat_result =
  if self.stat_res != nil:
    return self.stat_res[]
  result = stat(self.path)
  new self.stat_res
  self.stat_res[] = result

when InJs:
  func is_symlink*(self): bool = self.statObj.isSymbolicLink()
  template gen_is_x(is_x, jsAttr){.dirty.} =
    func is_x*(self): bool = 
      ## follow_symlinks is True on default.
      if self.is_symlink():
        let p = func_readlink $self.path
        statSync(p).jsAttr()
      else:
        self.statObj.jsAttr()
    func is_x*(self; follow_symlinks: bool): bool =
      if follow_symlinks: self.is_x()
      else: self.statObj.jsAttr()
  gen_is_x is_file, isFile
  gen_is_x is_dir, isDirectory
else:
  template gen_is_xAux(is_x, chk_pcX, chk_pcLinkToX){.dirty.} =
    func is_x*(self): bool =
      ## follow_symlinks is True on default.
      chk_pcX(self) or chk_pcLinkToX self
    func is_x*(self; follow_symlinks: bool): bool =
      ## result is cached. Python's is cached too.
      result = chk_pcX self
      if follow_symlinks:
        return result or chk_pcLinkToX self
  template gen_is_x(is_x, pcX, pcLinkToX) =
    template isPcX(self): bool = self.kind == pcX
    template isPcLinkX(self): bool = self.kind == pcLinkToX
    gen_is_xAux(is_x, isPcX, isPcLinkX)

  func is_symlink*(self): bool =
    ## ..warning:: this may differ Python's
    self.kind == pcLinkToDir or self.kind == pcLinkToFile
  when defined(windows):
    gen_is_x is_file, pcFile, pcLinkToFile
  else:
    from std/posix import Mode
    {.push header: "<sys/stat.h>".}
    let
      S_IFMT{.importc.}: Mode
      S_IFREG{.importc.}: Mode
    {.pop.}
    func isFReg(mode: Mode): bool{.inline.} =
      {.noSideEffect.}:
        result = (mode and S_IFMT) == S_IFREG
    func chk_isfile(self: DirEntry): bool{.inline.} =
      result = self.kind == pcFile
      if not result: return
      result = self.stat().st_mode.isFReg
    func chk_isSymlinkToFile(self: DirEntry): bool{.inline.} =
      result = self.is_symlink()
      if not result: return
      let p = readlink $self.path
      result = stat(p).st_mode.isFReg
    gen_is_xAux is_file, chk_isfile, chk_isSymlinkToFile
  gen_is_x is_dir, pcDir, pcLinkToDir

when defined(js):
  # readdirSync returns array, which might be too expensive.
  proc opendirSync(p: cstring): Dir{.importNode(fs, opendirSync).}
  proc closeSync(self: Dir){.importcpp.}
  proc readSync(self: Dir): Dirent{.importcpp.}

template scandirImpl(path){.dirty.} =
  let spath = $path
  when defined(js):
    var dir: Dir
    let cs = cstring($path)
    catchJsErrAndRaise:
      dir = opendirSync(cs)
    var dirent: Dirent
    while true:
      dirent = dir.readdirSync()
      let de = newDirEntry[T](name = $dirent.name.to(cstring), dir = spath, hasIsFileDir=dirent)
      if dirent.isNull: break

  else:
    try:
      for t in walkDir(spath, relative=true, checkDir=true):
        let de = newDirEntry[T](name = t.path, dir = spath, kind = t.kind)
        yield de
    except OSError as e:
      let oserr = e.errorCode.OSErrorCode
      path.raiseExcWithPath(oserr)

iterator scandir*[T](path: PathLike[T]): DirEntry[T] = scandirImpl path
iterator scandirIter*[T](path: T): DirEntry[T]{.closure.} =
  ## used by os.walk
  scandirImpl path

iterator scandir*(): DirEntry[PyStr] =
  for de in scandir[PyStr](str('.')):
    yield de

proc scandir*[T](path: PathLike[T]): ScandirIterator[T] =
  new result
  result.iter = iterator(): DirEntry[T] =
    for de in scandir[T](path): yield de

proc scandir*(): ScandirIterator[PyStr] =
  scandir[PyStr](str('.'))
