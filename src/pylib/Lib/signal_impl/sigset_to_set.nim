

import std/sets
import ./[pynsig, pylifecycle, abc_set]

proc add_sigset*(res: var Set[int], mask: var Sigset) =
  for sig in cint(1)..<cint(Py_NSIG):
    if sigismember(mask, sig) != 1:
      continue
    #[Handle the case where it is a member by adding the signal to
           the result list.  Ignore the other cases because they mean the
           signal isn't a member of the mask or the signal was invalid,
           and an invalid signal must have been our fault in constructing
           the loop boundaries.]#
    let signum = int sig
    res.add signum

proc sigset_to_set*(mask: var Sigset): HashSet[int] =
  result = initHashSet[int]()
  result.add_sigset mask
