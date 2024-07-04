
import ../../pyerrors/rterr
export NotImplementedError

template notImplErr*(meth) =
  raise newException(NotImplementedError, astToStr(meth) & " is not implemented")
