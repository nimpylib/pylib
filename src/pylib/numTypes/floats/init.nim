

from std/parseutils import parseFloat

import ../reimporter

template float*(a: PyStr|PyBytes): BiggestFloat =
  bind parseFloat, strip
  parseFloat strip $a

template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)
