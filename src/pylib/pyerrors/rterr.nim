
type
  RuntimeError* = object of CatchableError
  NotImplementedError* = object of RuntimeError
