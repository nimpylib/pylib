
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
import ./typing_impl/str_optional_obj
expOptObjCvt()
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
template wrapPyOptStr1(fun; T){.dirty.} =
  template fun*(obj: T): OptionalObj[PyStr] =
    newStrOptionalObj n_inspect.fun(obj)

wrapPyOptStr1 getmodulename, PyStr

wrapExportSincePy(3,12, markcoroutinefunction)

wrapExportSincePy(3,5, iscoroutinefunction)
wrapExportSincePy(3,5, isawaitable)

# isasyncgenfunction 3.6


template wrapPyStr1(fun){.dirty.} = wrapPyStr1(fun, untyped)
template wrapPyOptStr1(fun){.dirty.} = wrapPyOptStr1(fun, untyped)

wrapPyStr1 cleandoc, PyStr
wrapPyStr1 getfile
wrapPyOptStr1 getsourcefile
wrapPyStr1 getsource
wrapPyOptStr1 getdoc

template getsourcelines*(obj: typed): (PyList[PyStr], int) =
  ## get source code of the object:
  ##
  ## - the first element is the source code
  ## - the second element is the line number of the first line of the source code
  bind splitlines, getsourcelinesImpl
  getsourcelinesImpl(obj, splitlines)

# TODO:
# https://docs.python.org/3/library/inspect.html#introspecting-callables-with-the-signature-object
# https://docs.python.org/3/library/inspect.html#classes-and-functions
