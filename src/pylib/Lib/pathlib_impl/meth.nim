

import ./types
import std/os
import std/strutils

using self: types.Path

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

func `/`*(head: string, tail: Path): Path = Path(head) / tail
func `/`*(head: Path, tail: string): Path = head / Path(tail)

func joinpath*[P: string|Path](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i

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
