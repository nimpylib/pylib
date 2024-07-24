

from std/parseutils import parseFloat
import std/unicode
import ../../version
import ../../pystring/strimpl
import ../../pybytes/bytesimpl

template float*(f: SomeNumber): BiggestFloat = system.float(f)

template float*(a: PyStr|PyBytes): BiggestFloat =
  bind parseFloat, strip
  parseFloat strip $a

template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)
