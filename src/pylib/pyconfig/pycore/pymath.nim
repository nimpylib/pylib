## Py_ADJUST_ERANGE1 and Py_ADJUST_ERANGE2 are defined in pylib/builtins/private/pycore_pymath.nim
## as they're only required but complex-about routinues

import ../../private/trans_imp

impExp pymath,
  short_float_repr
