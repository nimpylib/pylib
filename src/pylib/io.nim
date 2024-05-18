##[

*NOTE*: not support js currently

## different from Python

### open
Its param: `closefd, opener`
is not implemented yet

### seek
There is difference that Python's `TextIOBase.seek`
will reset state of encoder at some conditions,
while Nim doesn't have access to encoder's state
Therefore, `seek` here doesn't change that

### iter over file
Python's `__next__` will yield newline as part of result
but Nim's `iterator lines` does not

]##

import ./Lib/io

export io.open, io.close, io.seek, io.read, io.readline, io.write, io.truncate
export io.raiseOsOrFileNotFoundError, io.initBufAsPy
