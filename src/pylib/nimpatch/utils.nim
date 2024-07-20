
const NimVersionTuple* = (NimMajor, NimMinor, NimPatch)

const JsBigInt64Option* = NimVersionTuple > (1, 6, 0) and compileOption("jsBigInt64")

template addPatch*(ver: (int, int, int), flag: bool, patchBody: untyped){.dirty.} =
  const
    FixedVer* = ver
    BeforeFixedVer* = NimVersionTuple < FixedVer
    Flag = flag
    hasBug* = BeforeFixedVer and Flag
  when hasBug:
    patchBody
  else:
    {.warning: currentSourcePath() & " patch takes no effect after " & $FixedVer.}
  