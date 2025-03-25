
template ifInvalidOnVcc*(signalnum: cint, handleExc) =
  when defined(windows):
    case signalnum
    of SIGABRT, SIGBREAK, SIGFPE, SIGILL, SIGINT, SIGSEGV, SIGTERM: discard
    else:
      handleExc

