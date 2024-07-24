

from std/parseutils import parseFloat
import ./parse_inf_nan
import ../utils/stripOpenArray
import ../reimporter

func float*(a: PyStr|PyBytes): BiggestFloat =
  let (m, n) = a.stripAsRange
  template stripped: untyped = ($a).toOpenArray(m, n)
  if Py_parse_inf_or_nan(result, stripped):
    return
  let ni = parseFloat(stripped, result)
  if ni != n - m + 1:
    raise newException(ValueError,
      "could not convert string to float: " & repr(a))

template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)
