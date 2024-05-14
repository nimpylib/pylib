
const weirdTarget = defined(nimscript) or defined(js)

when weirdTarget:
  discard
elif defined(windows):
  when defined(nimPreviewSlimSystem):
    import std/widestrs
  import std/winlean
elif defined(posix):
  import std/posix

when weirdTarget:
  {.pragma: noWeirdTarget, error: "this proc is not available on the NimScript/js target".}
else:
  {.pragma: noWeirdTarget.}

