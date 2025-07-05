
import ./strimpl

import ../stringlib/percent_format
import ../builtins/asciiImpl

import ../builtins/reprImpl
proc tpyreprImpl(s: string): string = pyreprImpl(s)  ## XXX: as pyreprImpl has a optional arg: escape127 so mismatch

genPercentAndExport PyStr, tpyreprImpl, pyasciiImpl, disallowPercentb=true
