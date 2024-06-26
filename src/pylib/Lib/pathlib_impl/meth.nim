

import ./types
import std/os
import std/strutils

using self: types.Path

func is_relative_to*(self; other: string): bool =
  {.noSideEffect.}:
    isRelativeTo($self, other)

func is_relative_to*(self; other: Path): bool = self.is_relative_to $other

func relative_to*(self; other: string|Path): Path =
  Path relativePath($self, $other)

proc absolute*(self): Path = Path absolutePath $self

func is_absolute*(self): bool = isAbsolute $self

func as_posix*(self): Path =
  Path replace($self, DirSep, '/')

#[ TODO(after urllib.parse.quote_from_bytes)
func as_uri*(self): Path =
  if not self.is_absolute():
    raise newException(
      ValueError, "relative path can't be expressed as a file URI")
]#

func `/`*(head: string, tail: Path): Path = Path(head) / tail
func `/`*(head: Path, tail: string): Path = head / Path(tail)

func joinpath*[P: string|Path](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i
