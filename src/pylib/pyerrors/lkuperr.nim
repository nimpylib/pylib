
type
  LookupError* = object of CatchableError  ##[
  .. warning:: Python's KeyError inherits LookupError,
  but Nim's doesn't, but inherits ValueError instead.
  ]##
