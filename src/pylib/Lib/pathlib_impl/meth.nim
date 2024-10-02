

import ./types
import std/os
when defined(js):
  from ../os_impl/osjsPatch import fileExists, dirExists, symlinkExists

import std/strutils

using self: types.Path

func `/`*(self; p: string): Path = self / Path($p)
func `/`*(p: string; self): Path = Path(p) / self

func `/=`*(head: var Path, tail: string): Path = head = head / tail

func joinpath*[P: string](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i

proc is_relative_to*(self; other: string): bool =
  isRelativeTo($self, other)

proc is_relative_to*(self; other: Path): bool = self.is_relative_to $other

func relative_to*(self; other: string|Path): Path =
  Path relativePath($self, $other)

proc absolute*(self): Path = Path absolutePath $self

template wrapPred(op, nop){.dirty.} =
  proc op*(self): bool = nop $self

wrapPred is_file, fileExists
wrapPred is_dir, dirExists
wrapPred is_symlink, symlinkExists

wrapPred is_absolute, isAbsolute

func as_posix*(self): Path =
  Path replace($self, DirSep, '/')

#[ TODO(after urllib.parse.quote_from_bytes)
func as_uri*(self): Path =
  if not self.is_absolute():
    raise newException(
      ValueError, "relative path can't be expressed as a file URI")
]#

func samefile*(self; other_path: string|Path): bool =
  sameFile($self, $other_path)

proc cwd*(_: typedesc[Path]): Path = Path getCurrentDir()
proc home*(_: typedesc[Path]): Path = Path getHomeDir()

proc open*(self; mode: FileMode): File =
  ## EXT.
  open($self, mode)

proc read_nstring*(self): string =
  ## EXT.
  readFile $self

proc write_nstring*(self, s: string) =
  ## EXT.
  writeFile $self, s


iterator iterdir*(self): Path =
  for i in walkDir($self, relative=true, checkDir=true):
    yield self / Path(i.path)

type IterDirGenerator = ref object
    iter: iterator(): Path
proc iterdir*(self): IterDirGenerator =
  result = IterDirGenerator(iter: iterator (): Path =
    for i in self.iterdir():
      yield i
  )

when not defined(js):
  proc mkdirParentsExistsOk*(self) =
    ## EXT.  equal to `path.mkdir(parents=True, exists_ok=True)`
    ##
    ## not for JS backend
    createDir $self

