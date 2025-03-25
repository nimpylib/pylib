
#[
class sigset_t_converter(CConverter):
    type = 'sigset_t'
    converter = '_Py_Sigset_Converter'
]#

import ./errutil, ./pynsig
import ../warnings

when defined(windows):
  import std/winlean
else:
  import std/posix except EINVAL
from std/strutils import format

template fromIterable*(result: var Sigset; obj) =
  bind warn, raiseErrno, format, Py_NSIG
  ## posixmodule.c `_Py_Sigset_Converter`
  if sigemptyset(result) < 0:
    raiseErrno() # Probably only if mask == NULL.
  var signum: cint
  var overflow: bool
  for item in obj:
      signum = cint item
      if signum <= 0 or signum >= Py_NSIG:
        if overflow or signum != -1:
          raise newException(ValueError,
          "signal number $# out of range [1; $#]".format(
                              signum, Py_NSIG - 1)
          )
          #error
      if sigaddset(result, signum) != 0:
        if isErr EINVAL:
          # Probably impossible
          raiseErrno()
        #[For backwards compatibility, allow idioms such as
        `range(1, NSIG)` but warn about invalid signal numbers]#
        warn("invalid signal number $#, please use valid_signals()".format(signum), RuntimeWarning, 1)
