discard """
  joinable: true
  batchable: true
"""

import pylib/builtins/min_max

template assertRaisesString[T](exc: typedesc[T]; errMsg: string; body) =
  try: body
  except exc as e: assert e.msg == errMsg, e.msg


assertRaisesString(ValueError, "max() iterable argument is empty"): discard max("")
assertRaisesString(ValueError, "min() iterable argument is empty"): discard min("")
