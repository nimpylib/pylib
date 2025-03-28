
import ./[pynsig, errutil, state, chk_util, pylifecycle, c_py_handler_cvt, frames]
import ./pyatomic

import ./enums
template toPySigHandler(handler: Handlers): PySigHandler =
  toPySigHandler case handler:
  of enums.SIG_DFL:
    pylifecycle.SIG_DFL
  of enums.SIG_IGN:
    pylifecycle.SIG_IGN

proc trip_signal(sig_num: cint){.inline.} =
  Py_atomic_store(Handlers[sig_num].tripped, true)

  # CPython has to handle Exeption in C level
  # but here we're in Nim, so no need

  # We minic `_PyErr_CheckSignalsTstate` here
  assert not Handlers[sig_num].fn.isNil
  Handlers[sig_num].fn(sig_num, getFrameOrNil(2))


proc signal_handler(sig_num: cint){.noconv.} =
  let save_errno = getErrno()

  trip_signal(sig_num)

  when not HAVE_SIGACTION:
    #[To avoid infinite recursion, this signal remains
       reset until explicit re-instated.
       Don't clear the 'func' field as it is our pointer
       to the Python handler...]#
    when declared(SIGCHLD):
      #[If the handler was not set up with sigaction, reinstall it.
        See Python/pylifecycle.c for the implementation of PyOS_setsig
        which makes this true.  See also issue8354.]#
      if sig_num != SIGCHLD:
        PyOS_setsig(sig_num, signal_handler)
    else:
      PyOS_setsig(sig_num, signal_handler)
  
  #[Issue #10311: asynchronously executing signal handlers should not
       mutate errno under the feet of unsuspecting C code.]#
  setErrnoRaw save_errno

  when DWin:
    if sig_num == SIGINT:
      setEvent(global_sigint_event)



proc signal*(signalnum: int, handler: PySigHandler): PySigHandler{.discardable.} =
  let signalnum = signalnum.cint
  signalnum.ifInvalidOnVcc:
    raise newException(ValueError, "invalid signal value")
  
  chkSigRng signalnum

  let fn = signal_handler

  if PyOS_setsig(signalnum, fn) == SIG_ERR:
    raiseErrno()
  
  result = get_handler(signalnum)
  set_handler(signalnum, handler)

proc signal*(signalnum: int, handler: CSigHandler|NimSigHandler): PySigHandler{.discardable.} =
  signal(signalnum, handler.toPySighandler)


proc default_int_handler*(signalnum: int, frame: PFrame) =
  raise newException(KeyboardInterrupt, "")

proc signal_get_set_handlers(state: signal_state_t) =
  for signum in cint(1)..<Py_NSIG.cint:
    let c_handler = PyOS_getsig signum
    let fn = if c_handler == SIG_DFL:
      state.default_handler
    elif c_handler == SIG_IGN:
      state.ignore_handler
    else:
      nil
    
    discard get_handler signum
    set_handler(signum, fn)
  
  # Install Python SIGINT handler which raises KeyboardInterrupt
  let sigint_func = get_handler(SIGINT)
  if sigint_func == state.default_handler:
    let int_handler = default_int_handler
    set_handler(SIGINT, int_handler)
    discard PyOS_setsig(SIGINT, signal_handler)

signal_get_set_handlers signal_global_state

