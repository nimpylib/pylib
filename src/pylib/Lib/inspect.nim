
import std/macros
import ./n_inspect
export n_inspect.getline

from ./inspect_impl/sourcegetters import getsourcelinesImpl, getdocNoDedentImpl
import ./inspect_impl/members
export isX except markcoroutinefunction

import ../builtins/list_decl
export list_decl

import ../pystring/strimpl
export strimpl
from ../pystring/strmeth import splitlines
import ../version

iterator getmembers*[T](obj: T): GetMemberType = members.getmembers(obj)
iterator getmembers*[T](obj: T, predict: GetMembersPredict): GetMemberType =
  members.getmembers(obj, predict)


template add(self: PyList, item: GetMemberType) =
  self.append(item)

template getmembers*(obj): PyList =
  bind getmembersImpl, allTrue, add, newPyList
  getmembersImpl[GetMembersType](obj, allTrue, newPyList[GetMembersType])

template getmembers*(obj; predict: GetMembersPredict): PyList =
  bind getmembersImpl, add, newPyList
  getmembersImpl[GetMembersType](obj, predict, newPyList[GetMembersType])

gen_getmembers_static pysince(3,11)


template wrapPyStr1(fun; T){.dirty.} =
  template fun*(obj: T): PyStr =
    str n_inspect.fun(obj)

wrapPyStr1 getmodulename, PyStr

template markcoroutinefunction*(obj): untyped{.pysince(3,12).} =
 isX.markcoroutinefunction(obj)

template defPredSince(sym, maj, min){.dirty.} =
  template sym*(obj): bool{.pysince(maj, min).} =
    isX.sym(obj)

defPredSince iscoroutinefunction, 3,5
defPredSince isawaitable, 3,5

# isasyncgenfunction 3.6


template wrapPyStr1(fun){.dirty.} = wrapPyStr1(fun, untyped)

wrapPyStr1 cleandoc, PyStr
wrapPyStr1 getfile
wrapPyStr1 getsourcefile
wrapPyStr1 getsource
wrapPyStr1 getdoc

macro getsourcelines*(obj: typed): (PyList[string], int) =
  ## get source code of the object
  ##
  ## the first element is the source code
  ## the second element is the line number of the first line of the source code
  newLit getsourcelinesImpl(obj, splitlines)

# TODO:
# https://docs.python.org/3/library/inspect.html#introspecting-callables-with-the-signature-object
# https://docs.python.org/3/library/inspect.html#classes-and-functions