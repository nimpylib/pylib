
import ../builtins/dict as dictLib
import ../builtins/dict_decl
import ../pystring/strimpl
export strimpl
export dictLib

import ./n_errno except errorcode
export n_errno except errorcode

declErrorcodeWith[int, PyStr] newPyDict
export errorcode
