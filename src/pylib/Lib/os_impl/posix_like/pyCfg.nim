
template importConfig*(name) =
  import ../../../pyconfig/name

import ../private/defined_macros
export defined_macros
when not InJS:
  const useMS_WINDOWSproc = MS_WINDOWS
else:
  const useMS_WINDOWSproc = false
export useMS_WINDOWSproc
