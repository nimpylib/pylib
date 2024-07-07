
import ../../pyerrors/[rterr, simperr, oserr, unicode_err]
export NotImplementedError, TypeError
export oserr, unicode_err

template notImplErr*(meth) =
  raise newException(NotImplementedError, astToStr(meth) & " is not implemented")
