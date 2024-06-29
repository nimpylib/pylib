
import std/strutils

type Warning* = enum
  UserWarning, DeprecationWarning, RuntimeWarning
# some simple impl for Python's warnings

proc formatwarning(message: string, category: Warning, filename: string, lineno: int, ): string =
  "$#:$#: $#: $#\n" % [filename, $lineno, $category, message]  # can use strformat.fmt

template warn*(message: string, category: Warning = UserWarning
    , stacklevel=1  #, source = None
  )=
  bind formatwarning
  let
    pos = instantiationInfo(index = stacklevel-2) # XXX: correct ?
    lineno = pos.line
    file = pos.filename
  stderr.write formatwarning(message, category, file, lineno)
