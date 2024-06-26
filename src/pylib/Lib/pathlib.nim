
import std/macros

import ../io_abc
import ../pystring/strimpl
#[ TODO:
import ../pybytes/bytesimpl
import ./os
func bytes*(self): PyBytes = os.fsencode($self)
]#

import ../builtins/list

import ./n_pathlib

macro wrapStr(aString: untyped, strings: untyped) =
  let nlib = ident "n_pathlib"
  result = newStmtList()
  var exp = nnkExportExceptStmt.newTree nlib
  for a in aString:
    exp.add a
    result.add quote do:
      func `a`*(self: types.Path): PyStr = str `nlib`.`a` self
  for a in strings:
    exp.add a
    result.add quote do:
      func `a`*(self: types.Path): PyList[PyStr] =
        result = newPyList[PyStr]()
        for i in `nlib`.`a` self:
          result.append str i
  result.add exp

wrapStr [
    name, suffix, stem
  ], [
    parts, suffixes
  ]

using self: Path
func fspath*(self): PyStr = str $self

proc Path*[P: PathLike](pathsegments: varargs[P]): types.Path =
  for i in pathsegments:
    result = result / i

func `/`*(self; p: PathLike): Path = self / Path($p)
func `/`*(p: PathLike; self): Path = Path($p) / self

func joinpath*[P: PathLike](self; pathsegments: varargs[P]): Path =
  result = self
  for i in pathsegments:
    result = result / i

