
import std/os
import ./types

using self: types.Path


template yield_splitWith(self;
    partitionFunc #[: proc(s: string): (string, string)): string]#) =
  var
    left = $self
    cur: string
  while left.len != 0:
    (left, cur) = left.partitionFunc
    yield cur

iterator parts*(self): string =
  ## Path.parts
  self.yield_splitWith splitPath

func parts*(self): seq[string] =
  ## Path.parts
  for i in self.parts:
    result.add i

func parent*(self): Path =
  Path parentDir $self

iterator parents*(self): Path =
  for i in parentDirs($self, inclusive=false):
    yield Path i

func parents*(self): seq[Path] =
  ## In Python: returns an immutable Sequence
  for i in self.parents:
    result.add i

func name*(self): string =
  # XXX: has ignored drive and UNC ? 
  lastPathPart $self

func with_name*(self; name: string): Path =
  self.parent / Path(name)

func partitionSuffix(s: string, lhs: static bool): string =
  let pos = s.searchExtPos
  template orelse(a, b): string =
    when lhs: a else: b
  if pos == -1:
    orelse s, ""
  else:
    orelse s[0..<pos], s[pos..^1]

func suffix*(self): string =
  let s = $self
  s.partitionSuffix false

func with_suffix*(self; suffix: string): Path =
  Path changeFileExt($self, suffix)

func splitSuffix(s: string): tuple[left, suffix: string] =
  let pos = s.searchExtPos
  if pos == -1: (s, "")
  else: (s[0..<pos], s[pos..^1])

iterator suffixes*(self): string =
  self.yield_splitWith splitSuffix

func suffixes*(self): seq[string] =
  for i in self.suffixes: result.add i

func stem*(self): string =
  result = self.name
  result = result.partitionSuffix true

