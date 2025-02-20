
template gen(name, lib){.dirty.} =
  template name* = import lib

gen import_pyconfig, ../pyconfig/main
gen import_dtoa, ../../impure/math/dtoa
gen import_obmalloc, ../../Objects/obmalloc

from ../../Lib/math_impl/errnoUtils import prepareRWErrno, setErrno0, isErr, ERANGE
import ../../impure/Python/mysnprintf

export
  prepareRWErrno, setErrno0, isErr, ERANGE,
  mysnprintf


from ../../Lib/math_impl/isX import isfinite
export isfinite
