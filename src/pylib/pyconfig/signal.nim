
import ./util
const Py_NSIG* = from_c_int(Py_NSIG, 64):
  {.emit:
"""/*INCLUDESECTION*/
#include <signal.h>
""".}
  {.emit:
"""/*VARSECTION*/
#ifdef _SIG_MAXSIG
   // gh-91145: On FreeBSD, <signal.h> defines NSIG as 32: it doesn't include
   // realtime signals: [SIGRTMIN,SIGRTMAX]. Use _SIG_MAXSIG instead. For
   // example on x86-64 FreeBSD 13, SIGRTMAX is 126 and _SIG_MAXSIG is 128.
#  define Py_NSIG _SIG_MAXSIG
#elif defined(NSIG)
#  define Py_NSIG NSIG
#elif defined(_NSIG)
#  define Py_NSIG _NSIG            // BSD/SysV
#elif defined(_SIGMAX)
#  define Py_NSIG (_SIGMAX + 1)    // QNX
#elif defined(SIGMAX)
#  define Py_NSIG (SIGMAX + 1)     // djgpp
#else
#  define Py_NSIG 64               // Use a reasonable default value
#endif
""".}

AC_LINK_IFELSE HAVE_STRSIGNAL, false:
  proc strsignal(signalnum: cint): cstring {.importc, header: "<string.h>".}
  discard strsignal(0)

const DEF_SIG* = low int  ## we know int.low is smaller than low(cint)
when not defined(windows):
  template SIG(sym) =
    const sym* = from_c_int(sym, "<signal.h>", DEF_SIG)

  SIG SIGIOT
  SIG SIGEMT
  SIG SIGCLD
  SIG SIGPWR
  SIG SIGIO
  SIG SIGWINCH
  SIG SIGRTMIN
  SIG SIGRTMAX
  SIG SIGSTKFLT
