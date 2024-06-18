# Nim Pylib

## import pylib
The mostly suggested style is
```Nim
import pkg/pylib
```

However, omitting the `pkg/` prefix shall be fine at most cases:

```Nim
import pylib
```

## import Python-like stdlib
Cheatsheet for alternative between pylib and Python

| Nim pylib                        | Python                               |
| --------------------------       | --------------------------           |
| `from pylib/Lib/LIB import nil`  | `import LIB`                         |
| `import pylib/Lib/LIB`           | `from LIB import *`                  |
| `from pylib/Lib/LIB import XXX`  | `import LIB; from LIB import XXX`    |

