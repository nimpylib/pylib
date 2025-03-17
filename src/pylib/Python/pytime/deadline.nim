
import ./monotonic, ./types, ./ops
export types

proc PyDeadline_Init*(timeout: PyTime): PyTime =
  discard monotonicRaw(result)
  discard result.iadd timeout

proc PyDeadline_Get*(deadline: PyTime): PyTime =
  discard monotonicRaw(result)
  result = deadline - result

