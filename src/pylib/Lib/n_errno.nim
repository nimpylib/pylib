
import std/tables
import ./errno_impl/[errnoUtils, errnoConsts]
export errnoUtils except Errno, initErrorcodeMap

export errnoConsts

import ./errno_impl/private/singleton_errno
export errno

declErrorcodeWith[int, string] initTable
export errorcode
