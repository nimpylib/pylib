
import ../../pyerrors/[rterr, simperr]
export NotImplementedError, TypeError

template notImplErr*(meth) =
  raise newException(NotImplementedError, astToStr(meth) & " is not implemented")
