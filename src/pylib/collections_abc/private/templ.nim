
template closeImpl*(msg: string; throwBody) =
  try:
    throwBody
    raise newException(RuntimeError, msg & " ignored GeneratorExit")
  except (GeneratorExit, StopIteration):
    discard
