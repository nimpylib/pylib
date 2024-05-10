
import ../../[io_abc, pyerrors]
import ../../pystring/strimpl
import ../../builtins/reprImpl

export io_abc, pyerrors, strimpl, reprImpl

template AltPathType*(T): untyped =
  when T is char: PyStr else: T

type OsPathDefType* = PyStr