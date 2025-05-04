
import std/os
import ../common
import ./stat

when not InJs:
  import ../../n_stat
import ./pyCfg
importConfig [os]
when HAVE_FDOPENDIR:
  when HAVE_FDOPENDIR_RUNTIME:
    import ./errnoUtils

when InJs:
  import std/jsffi
  import ./links
  type
    Dir = JsObject  ## fs.Dir
    Dirent = JsObject  ## fs.Dirent
  from ./jsStat import Stat, statSync
elif defined(posix):
  import ./links
  import std/posix except S_ISREG, S_ISDIR, S_ISLNK
when declared(readlink):
  func func_readlink(x: string): string =
    {.noSideEffect.}:
      result = readlink(x)

type
  DirEntryImpl[T] = ref object of RootObj
    when T is int:
      name*, path*: PyStr
    else:
      name*, path*: T
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
const havePDir = declared(Dir)
type ScandirIterator[T] = ref object
    when havePDir:
      when T is int:
        dirp: ptr Dir
    iter: iterator(): DirEntry[T]

func close*(scandirIter: ScandirIterator) = discard
func close*(scandirIter: ScandirIterator[int]) =
  when havePDir and not InJs:
    discard closedir scandirIter.dirp
    scandirIter.dirp = nil
iterator items*[T](scandirIter: ScandirIterator[T]): DirEntry[T] =
  for i in scandirIter.iter():
    yield i

template enter*(self: ScandirIterator): ScandirIterator = self
template exit*(self: ScandirIterator; args: varargs[untyped]) =
  bind close
  self.close()

using self: DirEntry

when InJs:
  proc newDirEntry[T](name: string, dir: string, hasIsFileDir: JsObject
  ): DirEntry[T] =
    new result
    result.name = mapPathLike[T] name
    result.path = mapPathLike[T] joinPath(dir, name)
    result.statObj = hasIsFileDir
else:
  proc newDirEntry[T](name: string, dir: string|int, kind: PathComponent
  ): DirEntry[T] =
    new result
    when T is int:
      result.name = str name
      result.path = result.name
    else:
      result.name = mapPathLike[T] name
      result.path = mapPathLike[T](joinPath(dir, name))
    result.kind = kind

func repr*(self): string =
  "<DirEntry " & self.name.repr & '>'

proc stat*(self; follow_symlinks=true): stat_result =
  static: assert not compiles(self.dir_fd) # currently impl assumes no dir_fd
  if self.stat_res != nil:
    return self.stat_res[]
  result = stat(self.path, follow_symlinks=follow_symlinks)
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
    func isFReg(mode: Mode): bool{.inline.} =
      {.noSideEffect.}:
        result = mode.S_ISREG
    func chk_isfile(self: DirEntry): bool{.inline.} =
      result = self.kind == pcFile
      if not result: return
      result = self.stat().st_mode.isFReg
    func isLinkToFile(path: string; dir_fd=DEFAULT_DIR_FD): bool{.inline.} =
      let p = func_readlink path
      {.noSideEffect.}:
        result = stat(p, dir_fd=dir_fd).st_mode.isFReg
    func chk_isSymlinkToFile(self: DirEntry): bool{.inline.} =
      result = self.is_symlink()
      if not result: return
      isLinkToFile $self.path
    gen_is_xAux is_file, chk_isfile, chk_isSymlinkToFile
  gen_is_x is_dir, pcDir, pcLinkToDir

proc is_junction*(self): bool =
  when not defined(windows): false
  else:
    stat(self).st_reparse_tag == IO_REPARSE_TAG_MOUNT_POINT

when defined(js):
  # readdirSync returns array, which might be too expensive.
  proc opendirSync(p: cstring): Dir{.importNode(fs, opendirSync).}
  proc closeSync(self: Dir){.importcpp.}
  proc readSync(self: Dir): Dirent{.importcpp.}

when HAVE_FDOPENDIR:
  when HAVE_FDOPENDIR_RUNTIME:
    when not declared(fdopendir):
      proc fdopendir*(fd: cint): ptr Dir{.importc, header: "<dirent.h>".}
    const HAVE_DIRENT_D_TYPE = compiles(Dirent().d_type)

    proc nimPCKindFromDirent(dir_fd: int, name: string, direntp: ptr Dirent): PathComponent =
      ## Determine the PathComponent kind based on the Dirent structure.
      when HAVE_DIRENT_D_TYPE:
        case direntp.d_type
        of DT_DIR:
          return pcDir
        of DT_REG:
          return pcFile
        of DT_LNK:
          return pcLinkToFile  # Assuming symbolic links are treated as links to files
        of DT_UNKNOWN:
          discard  # Fall back to stat if d_type is unknown
        else:
          discard  # Unsupported d_type, fallback to stat
      # If d_type is not available, fallback to stat
      let st = stat(name, dir_fd=dir_fd)
      if S_ISDIR(st.st_mode):
        return pcDir
      elif S_ISREG(st.st_mode):
        return pcFile
      elif S_ISLNK(st.st_mode):
        if isLinkToFile(name, dir_fd=dir_fd):
          return pcLinkToFile
        else:
          return pcLinkToDir
      else:
        doAssert false, "unreachable"

type ScandirNotSupportFd = object of RootEffect
proc eScandirType{.tags: [ScandirNotSupportFd].} =
  raise newException(TypeError,
  "scandir: path should be string, bytes, os.PathLike or None, not int")
template scandirImpl(path){.dirty.} =
  sys.audit("os.scandir", path)
  when path is int:
    when HAVE_FDOPENDIR:
      when HAVE_FDOPENDIR_RUNTIME:
        var dirp = fdopendir(cint path)
        if dirp.isNil:
          raiseErrnoWithPath($path)
        # ScandirIterator_iternext
        while true:
          setErrno0()
          var direntp = dirp.readdir()
          if direntp.isNil:
            if isErr0():
              break
            raiseErrnoWithPath($path)
          let cname = direntp.d_name
          let is_dot = cname[0] == '.' and (
            cname[1] == '\0' or (cname[1] == '.' and cname[2] == '\0')
          )
          if not is_dot:
            let name = $cname
            let de = newDirEntry[T](name = name, dir = path,
              kind=nimPCKindFromDirent(path, name, direntp))
            yield de
      else:
        eScandirType()
    else:
      eScandirType()
  else:
    let spath = $path
    when defined(js):
      var dir: Dir
      let cs = cstring($path)
      catchJsErrAndRaise:
        dir = opendirSync(cs)
      var dirent: Dirent
      while true:
        dirent = dir.readSync()
        if dirent.isNull: break
        let de = newDirEntry[T](name = $dirent["name"].to(cstring), dir = spath, hasIsFileDir=dirent)
        yield de
      dir.closeSync

    else:
      tryOsOp(spath):
        for t in walkDir(spath, relative=true, checkDir=true):
          let de = newDirEntry[T](name = t.path, dir = spath, kind = t.kind)
          yield de

iterator scandir*[T](path: PathLike[T]): DirEntry[T] = scandirImpl path
iterator scandir*(path: int): DirEntry[int] =
  type T = int
  scandirImpl path
iterator scandirIter*[T](path: T): DirEntry[T]{.closure.} =
  ## used by os.walk
  scandirImpl path

iterator scandir*(): DirEntry[PyStr] =
  for de in scandir[PyStr](str('.')):
    yield de

template scandirProcImpl(path){.dirty.} =
  new result
  result.iter = iterator(): DirEntry[T] =
    for de in scandir(path): yield de

proc scandir*[T](path: PathLike[T]): ScandirIterator[T] =
  scandirProcImpl(path)
proc scandir*(path: int): ScandirIterator[int] =
  type T = int
  scandirProcImpl(path)

proc scandir*(): ScandirIterator[PyStr] =
  scandir[PyStr](str('.'))
