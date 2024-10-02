

import ./parsefloat
import ../utils/stripOpenArray
import ../reimporter
import ../../nimpatch/floatdollar

proc repr*(x: SomeFloat): string =
  floatdollar.`$` x

template float*(number: SomeNumber = 0.0): BiggestFloat = BiggestFloat number

func pyfloat(a: string|PyStr|PyBytes): BiggestFloat =
  ## `PyFloat_FromString`.
  ## the same as `float(str|bytes)`
  # used by builtins.complex
  let sa = $a
  let (m, n) = sa.stripAsRange
  let ni = parsePyFloat(sa.toOpenArray(m, n), result)
  if ni != n - m + 1:
    raise newException(ValueError,
      "could not convert string to float: " & repr(a))

func float*(a: PyStr|PyBytes): BiggestFloat = pyfloat(a)

template float*(a: bool): BiggestFloat = (if a: 1.0 else: 0.0)

type HasIndex = concept self
  self.index() is SomeInteger

template float*(obj: HasIndex): BiggestFloat{.pysince(3,8).} = BiggestFloat obj.index()
