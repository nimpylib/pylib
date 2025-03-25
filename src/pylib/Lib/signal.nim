
import ./n_signal
import ../builtins/set
import ./collections/abc

when defined(unix):
  proc sigpending*(): PySet[int] = newPySet n_signal.sigpending()

  proc pthread_sigmask*(how: int, mask: Sigset): PySet[int] =
    newPySet n_signal.pthread_sigmask(how, mask)

  converter toSigset*(oa: Iterable[int]): Sigset =
    ## Py_Sigset_Converter
    result.fromIterable oa


export n_signal except sigpending, pthread_sigmask
