##[  Macros to protect CRT calls against instant termination when passed an
 invalid parameter (bpo-23524). IPH stands for Invalid Parameter Handler.

CPython/Include/internal/pycore_fileutils.h
]##

const MS_WINDOWS* = defined(windows)

when MS_WINDOWS and defined(vcc):
  let MSC_VER{.importc: "_MSC_VER", nodecl.}: cint
  type
    wchar_t{.importc, header: "<wchar.h>".} = int16
    uintptr_t{.importc, header: "<stddef.h>"} = (
      when sizeof(cuint) == 4: uint64 else: cuint)
  type wcharp = ptr wchar_t
  proc slientInvalParamHandler(
   expression, function, file: wcharp,
   line: cuint, pReserved: uintptr_t){.cdecl.} = discard
  type InvalParamHandler{.importc: "_invalid_parameter_handler".} =
    typeof slientInvalParamHandler
  proc setTLinvalParamHandler(pNewL: InvalParamHandler): InvalParamHandler{.
    importc: "_set_thread_local_invalid_parameter_handler",
    header: "<stdlib.h>".}
  template with_Py_SUPPRESS_IPH*(body) =
    bind setTLinvalParamHandler, slientInvalParamHandler
    if MSC_VER >= 1900:
      let oldHandler = setTLinvalParamHandler slientInvalParamHandler
      body
      discard setTLinvalParamHandler oldHandler
    else:
      body
else:
  template with_Py_SUPPRESS_IPH*(body) = body

