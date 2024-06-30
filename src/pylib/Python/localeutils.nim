

{.push header: "<locale.h>".}
let LC_ALL*{.importc.}: cint
let LC_CTYPE*{.importc.}: cint
proc c_setlocale*(category: cint, v: cstring): cstring{.importc: "setlocale".}
{.pop.}

template setlocale*(category; v: string): cstring =
  ## we know setlocale won't modify 2nd param
  ## Thus `v: string` is allowed to convert to cstring implicitly
  bind c_setlocale
  c_setlocale category, v
