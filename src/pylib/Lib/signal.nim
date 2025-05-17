
import ./n_signal
import ./signal_impl/valid_signals_impl

import ../builtins/set
import ../pystring/strimpl
import ./typing_impl/str_optional_obj
expOptObjCvt()
import ../version

export n_signal except sigpending, pthread_sigmask, strsignal, valid_signals

import std/macros
macro mayUndef(def) =
  let cond = newCall("declared", def.name)
  result = nnkWhenStmt.newTree(nnkElifBranch.newTree(cond, def))

proc sigpending*(): PySet[int]{.mayUndef.} = newPySet n_signal.sigpending()

proc pthread_sigmask*(how: int, mask: Sigset): PySet[int]{.mayUndef.} =
  newPySet n_signal.pthread_sigmask(how, mask)

  #[ XXX: NIM-BUG: compiler stuck here
  import ./signal_impl/sigsetCvt
  import ./collections/abc
  converter toSigset*(oa: Iterable[int]): Sigset =
    ## Py_Sigset_Converter
    result.fromIterable oa
  ]#

proc strsignal*(signalnum: int): OptionalObj[PyStr]{.pysince(3,8).} =
  newStrOptionalObj n_signal.strsignal signalnum

when have_valid_signals:
  proc valid_signals*(): PySet[int]{.pysince(3,8).} =
    result = newPySet[int]()
    result.fill_valid_signals()
