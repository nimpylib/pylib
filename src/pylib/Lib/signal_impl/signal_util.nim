import ../../private/iph_utils
import ../../pyconfig/ver
import ./siginfo_decl
import ./[state, chk_util, pylifecycle, pynsig, c_api]

when HAVE_STRSIGNAL:
  import ./errutil
  proc strsignal(signalnum: cint): cstring {.importc, header: "<string.h>".}

  proc strstr(s, subs: cstring): ptr char{.importc, header: "<string.h>".}

proc getsignal*(signalnum: int): PySigHandler =
  signalnum.chkSigRng
  result = get_handler(cast[cint](signalnum))

proc strsignal*(signalnum: int): string =
  ## returns empty string over `None`
  signalnum.chkSigRng
  let signalnum = cast[cint](signalnum)
  when HAVE_STRSIGNAL:
    setErrno0()
    let res = strsignal(signalnum)

    if getErrno() != 0 or res.isNil or
        not strstr(res, "Unknown signal").isNil:
      return

    result = $res
  else:
    # Though being a UNIX, HP-UX does not provide strsignal(3).
    const DEF = ""
    result = case signalnum:
    of SIGINT:  "Interrupt"
    of SIGILL:  "Illegal instruction"
    of SIGABRT: "Aborted"
    of SIGFPE:  "Float-point exception"
    of SIGSEGV: "Segmentation fault"
    of SIGTERM: "Terminated"
    elif not defined(windows):
      case signalnum
      of SIGHUP:  "Hangup"
      of SIGALRM: "Alarm clock"
      of SIGPIPE: "Broken pipe"
      of SIGQUIT: "Quit"
      of SIGCHLD: "Child exited"
      else: DEF
    else: DEF


proc c_raise*(signalnum: cint): cint {.importc: "raise", header: "<signal.h>".}

proc raise_signal*(signalnum: int) =
  let signalnum = cast[cint](signalnum)
  var err: cint
  with_Py_SUPPRESS_IPH:
    err = c_raise(signalnum)
  if err != 0:
    raiseErrno()
  PyErr_CheckSignalsAndRaises()

when defined(linux) and not (
    defined(android) and ANDROID_API < 31):
  proc syscall(sysno: cint): cint {.varargs, importc: "syscall", header: "<sys/syscall.h>".}
  let NR_pidfd_send_signal{.importc: "__NR_pidfd_send_signal", header: "<unistd.h>".}: cint
  # SYS_pidfd_send_signal is its newer name
  proc pidfd_send_signal*(pid: int, sig: int,
      siginfo: struct_siginfo = nil, flags = 0) =
    let pid = cint(pid)
    let sig = cint(sig)
    if syscall(NR_pidfd_send_signal, pid, sig, nil, flags) < 0:
      raiseErrno()
