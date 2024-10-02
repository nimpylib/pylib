
import ./types

proc Path*[P](pathsegments: varargs[P]): types.Path =
  for i in pathsegments:
    result = result / i

