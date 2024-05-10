
import ../../[io_abc, pyerrors]
import ../../pystring/strImpl
import ../../builtins/reprImpl

export io_abc, pyerrors, strImpl, reprImpl

template AltPathType*(T): untyped =
  when T is char: PyStr else: T

type OsPathDefType* = PyStr