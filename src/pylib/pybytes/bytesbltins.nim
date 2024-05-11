
from std/algorithm import reversed
import ./bytesimpl
from ../pyerrors import TypeError
import ../builtins/reprImpl

func reversed*(s: PyBytes): PyBytes =
  pybytes reversed $s

proc ord*(a: PyBytes): int =
  ## Raises TypeError if len(a) is not 1.

  when not defined(release):
    let ulen = a.len
    if ulen != 1:
      raise newException(TypeError, 
        "TypeError: ord() expected a character, but string of length " & $ulen & " found")
  result = a[0]

func repr*(x: PyBytes): string =
  ## Overwites `system.repr` for `PyBytes`
  ## 
  ## minics Python's
  'b' & pyreprImpl $x

