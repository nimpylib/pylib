

from std/parseutils import parseFloat
import ./parse_inf_nan
import ../utils/stripOpenArray
import ../reimporter

template float*(number: SomeNumber = 0.0): BiggestFloat = BiggestFloat number

func parsePyFloat*(a: string|PyStr|PyBytes): BiggestFloat =
  ## EXT. the same as `float(str|bytes)`
  # used by builtins.complex
  let sa = $a
  let (m, n) = sa.stripAsRange
  template stripped: untyped = (sa).toOpenArray(m, n)
  if Py_parse_inf_or_nan(result, stripped):
    return
  let ni = parseFloat(stripped, result)
  if ni != n - m + 1:
    raise newException(ValueError,
      "could not convert string to float: " & repr(a))

func float*(a: PyStr|PyBytes): BiggestFloat = parsePyFloat(a)

template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)

type HasIndex = concept self
  self.index() is SomeInteger

template float*(obj: HasIndex): BiggestFloat{.pysince(3,8).} = BiggestFloat obj.index()
