
const NimVersionTuple* = (NimMajor, NimMinor, NimPatch)

const JsBigInt64Option* = NimVersionTuple > (1, 6, 0) and compileOption("jsBigInt64")

template addPatch*(ver: (int, int, int),
    flag: untyped#[bool, use untyped to make flagExprRepr work]#,
    patchBody: untyped){.dirty.} =
  ##  flag is a bool expr, here uses untyped to delay evaluation
  ##   to get its string represent
  const
    FixedVer* = ver
    BeforeFixedVer* = NimVersionTuple <= FixedVer
    Flag = flag
    hasBug* = BeforeFixedVer and Flag
  when hasBug:
    patchBody
  else:
    const flagExprRepr = astToStr(flag)
    {.warning: currentSourcePath() & " patch only takes effect before " & $FixedVer &
      " or without flags: " & flagExprRepr.}
  