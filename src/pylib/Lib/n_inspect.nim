
import std/macros
import ../private/inspect_cleandoc
import ./inspect_impl/[
    sourcegetters, isX, members, modulename
    ]
export isX
export sourcegetters except getsourcelinesImpl, getdocNoDedentImpl
export members except getmembersImpl

from std/strutils import splitLines

proc getmodulename*(obj: string): string =
  ## PY-DIFF: This cannot returns None,
  ##   but may raise a ValueError.
  if getmodulenameImpl(obj, result):
    return
  raise newException(ValueError, "Object is not a module, type, or proc.")


func cleandoc*(s: string): string{.inline.} =
  ## Cleans up a docstring by removing leading whitespace and trailing newlines.
  ##
  ## The first line of the docstring is also removed, as it is assumed to be
  ## the docstring's summary.
  ##
  ## The docstring is also trimmed of leading and trailing whitespace.
  ##
  `inspect.cleandoc` s


macro getsourcelines*(obj: typed): (seq[string], int) =
  newLit getsourcelinesImpl(obj, splitLines)

macro getdoc*(obj: typed): string =
  newLit cleandoc getdocNoDedentImpl(obj)

when isMainModule:
  static:
    echo getsource cleandoc
