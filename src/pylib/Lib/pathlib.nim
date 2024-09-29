
import std/macros

import ./[
  os, io
]

import ../io_abc
import ../pystring/strimpl
#[ TODO:
import ../pybytes/bytesimpl
import ./os
func bytes*(self): PyBytes = os.fsencode($self)
]#

import ../builtins/list
import ../version

import ./n_pathlib

macro wrapStr(aString: untyped, strings: untyped; excludes: untyped) =
  let nlib = ident "n_pathlib"
  result = newStmtList()
  var exp = nnkExportExceptStmt.newTree nlib
  let argName = ident"self" 
  for a in aString:
    exp.add a
    result.add quote do:
      func `a`*(`argName`: types.Path): PyStr = str `nlib`.`a` `argName`
  for a in strings:
    exp.add a
    result.add quote do:
      func `a`*(`argName`: types.Path): PyList[PyStr] =
        result = newPyList[PyStr]()
        for i in `nlib`.`a` `argName`:
          result.append str i
  for i in excludes: exp.add i
  result.add exp

wrapStr [
    name, suffix, stem
  ], [
    parts, suffixes
  ], [
    read_nstring, write_nstring
  ]

using self: Path
func fspath*(self): PyStr = str $self

proc Path*[P: PathLike](pathsegments: varargs[P]): types.Path =
  for i in pathsegments:
    result = result / i

func `/`*(self; p: PathLike): Path = self / Path($p)
func `/`*(p: PathLike; self): Path = Path($p) / self

func `/=`*(head: var Path, tail: PathLike): Path = head = head / Path($tail)

func joinpath*[P: PathLike](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i

template open*(self: Path, mode: StringLike = "r",
    buffering = -1,
    encoding=DefEncoding, errors=DefErrors, newline=DefNewLine): untyped =
  bind open
  open($self, mode, buffering, encoding, errors, newline)


proc read_text*(self; encoding=DefEncoding, errors=DefErrors): PyStr =
  var f = open($self, encoding=encoding, errors=errors)
  defer: f.close()
  result = f.read()

proc write_text*(self; data: PyStr, encoding=DefEncoding, errors=DefErrors
    ): int{.discardable.} =
  var f = open($self, encoding=encoding, errors=errors)
  defer: f.close()
  result = f.write(data)

proc read_bytes*(self): PyBytes = bytes readFile $self
proc write_bytes*(self; b: PyBytes) = writeFile $self, $b

proc readlink*(self): Path = Path os.readlink $self

proc symlink_to*(self; target: string|Path; target_is_directory=false) =
  os.symlink($self, $target, target_is_directory)

proc hardlink_to*(self; target: string|Path){.pysince(3,10).} =
  os.link($self, $target)

proc unlink*(self) =
  ## for missing_ok==False
  os.unlink $self

proc unlink*(self; missing_ok: bool) =
  if not missing_ok:
    self.unlink
    return
  try:
    os.unlink $self
  except FileNotFoundError:
    discard

template reXX(rename){.dirty.} =
  proc rename*(self; target: Path): Path{.discardable.} =
    os.rename($self, $target)
    target

  proc rename*(self; target: string): Path{.discardable.} =
    rename(self, Path(target))

reXX rename
reXX replace

proc mkdirParents(self; exist_ok=false) =
  ## for parents==False
  if not exist_ok and existsOrCreateDir $self:
    raiseExcWithPath $self

proc mkdir*(self; mode = 0o777, parents: bool, exist_ok=false) =
  if parents:
    self.mkdirParents exist_ok
  else:
    if not exist_ok:
      os.mkdir($self, mode=mode)
      return
    try:
      os.mkdir($self, mode=mode)
    except FileExistsError:
      discard

proc rmdir*(self) = os.rmdir $self

proc touch*(self; mode=0o666, exist_ok=true) =
    ## Create this file with the given access mode, if it doesn't exist.
    
    let s = $self
    if exist_ok:
        # First try to bump modification time
        # Implementation note: GNU touch uses the UTIME_NOW option of
        # the utimensat() / futimens() functions.
        try:
            os.utime(s)
            return
        except OSError:
            # Avoid exception chaining
            discard
    var flags = os.O_CREAT | os.O_WRONLY
    if not exist_ok:
        flags |= os.O_EXCL
    let fd = os.open(s, flags, mode)
    os.close(fd)

proc stat*(self): stat_result = os.stat($self)

# TODO: stat(..., follow_symlinks), see os
# and exists
