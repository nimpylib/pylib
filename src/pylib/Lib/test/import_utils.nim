
template pyimport*(nam) =
  import ../nam

template importPyLib* = import ../../../pylib

template importPyLib*(lib) =
  importPyLib()
  pyimport lib

template importTestPyLib*(lib) =
  import std/unittest
  importPyLib lib
