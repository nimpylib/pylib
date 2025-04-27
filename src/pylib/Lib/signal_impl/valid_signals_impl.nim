
import ./[pylifecycle, sigset_to_set, errutil, abc_set]

const have_valid_signals* = defined(windows) or HAVE_SIGFILLSET and HAVE_SIGSET_T
when have_valid_signals:
  proc fill_valid_signals*(res: var Set[int]) =
    when defined(windows):
      for i in [SIGABRT, SIGFPE,
              SIGILL, SIGINT, SIGSEGV, SIGTERM]:
        res.add int i
      when declared(SIGBREAK):
        res.add int SIGBREAK
    else:
      var mask: SigSet
      if sigemptyset(mask) != 0 or sigfillset(mask) != 0:
        raiseErrno()
      res.add_sigset mask
