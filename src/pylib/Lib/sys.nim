## Lib/sys
##
## .. hint:: if not defined `pylibConfigIsolated`,
##   this module will call `setlocale(LC_CTYPE, "")`,
##   a.k.a. changing locale to user's configure,
##   just as CPython's initialization.

import ../builtins/list
import ../noneType
import ../pystring/strimpl

import ./n_sys
export n_sys except float_repr_style, platform, getencodings

import ./sys_impl/[genplatform, geninfos, genargs]
const float_repr_style* = str(n_sys.float_repr_style)
genPlatform(str)
genInfos(str, None)
genArgs PyStr, PyList, str, list, newPyListOfCap
export list, strimpl

when declared(sys_impl_stdio.stdout):
  converter noneStdstream*(n: NoneType): typeof(sys_impl_stdio.stdout) = nil

template wrapStrProc(fun) =
  proc fun*(): PyStr = str n_sys.fun()

wrapStrProc getfilesystemencoding
wrapStrProc getdefaultencoding

func exit*[T](obj: T) =
  ## .. warning:: this does not raise SystemExit,
  ##   which differs Python's
  exit(str(obj))
func exit*(x: NoneType) = quit(0)

