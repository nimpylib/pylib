
import ./[state, chk_util, pylifecycle, pynsig]

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

