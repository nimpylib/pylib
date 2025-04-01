
import ../../n_errno
import ../../signal_impl/c_api
from ../common import raiseErrno

template initVal_with_handle_signal*[R](res: var R; resExpr){.dirty.} =
  bind isErr, EINTR, PyErr_CheckSignals, raiseErrno
  var async_err: int

  while true:
    res = resExpr
    if res >= 0 or isErr(EINTR):
      break
    async_err = PyErr_CheckSignals()
    if async_err != 0:
      break
  if res < 0:
    raiseErrno()
