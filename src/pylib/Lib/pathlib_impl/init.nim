
import ./types

proc Path*[P: Path|string](pathsegments: varargs[P]): types.Path =
  for i in pathsegments:
    result = result / i

