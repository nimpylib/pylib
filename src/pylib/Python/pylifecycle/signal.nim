

import ./signal/[
  handler_types, c_syms
]

when not HAVE_SIGACTION:
  import ./signal/chk_util

export handler_types

proc PyOS_getsig*(sig: cint): CSighandler =
  when HAVE_SIGACTION:
    var context: Sigaction
    if sigaction(sig, nil, context) == -1:
      return SIG_ERR
    return context.sa_handler
  else:
    sig.ifInvalidOnVcc:
      return SIG_ERR

    result = c_signal(sig, SIG_IGN)
    if result != SIG_ERR:
      discard c_signal(sig, result)

proc PyOS_setsig*(sig: cint, handler: CSighandler): CSighandler =
  ## Python/pylifecycle.c PyOS_setsig
  when HAVE_SIGACTION:
    #[Some code in Modules/signalmodule.c depends on sigaction() being
    used here if HAVE_SIGACTION is defined.  Fix that if this code
    changes to invalidate that assumption.]#
    var context, ocontext: Sigaction
    context.sa_handler = handler
    discard sigemptyset(context.sa_mask)
    #[Using SA_ONSTACK is friendlier to other C/C++/Golang-VM code that
    extension module or embedding code may use where tiny thread stacks
    are used.  https://bugs.python.org/issue43390 */]#
    context.sa_flags = SA_ONSTACK
    if sigaction(sig, context, ocontext) == -1:
      return SIG_ERR
    return ocontext.sa_handler
  else:
    result = c_signal(sig, handler)
    when declared(siginterrupt):
      siginterrupt(sig, 1)
