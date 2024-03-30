
## see docs.python.org/3/library/os.html
## 
## Also export everything of std/os
## 
## as the following will fail to compile:
## 
## ```Nim
## import std/os
## import pylib/Lib/os
## os.path.join ...
## ```
## 
## not completed yet

import std/os
export os

import ./os_impl/[consts, fdopen, open_close, utils, path]
export consts, fdopen, open_close, utils, path


