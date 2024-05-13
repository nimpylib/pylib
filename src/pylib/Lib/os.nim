
## see docs.python.org/3/library/os.html
## 
## Also export everything of std/os

import std/os
export os

import ./os_impl/[consts, posix_like, subp, utils, path, walkImpl, listdirx]
export consts, posix_like, subp, utils, path, walkImpl, listdirx


