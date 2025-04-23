
import std/options
import ../private/trans_imp

import ./sys_impl/[
  genplatform, geninfos, genargs
]
template asis[T](x: T): T = x
genPlatform(asis)
genInfos(asis, none(string))
template append(x: seq, y) = x.add y
genArgs string, seq, asis, asis, newSeqOfCap

impExp sys_impl,
  fenvs,
  stdio,
  exits,
  getencodings,
  sizes,
  flagsImpl,
  auditImpl


