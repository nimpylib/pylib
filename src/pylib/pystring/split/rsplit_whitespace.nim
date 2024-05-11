
import ./common
import ./reimporter

proc rsplit_whitespace*(pystr: PyStr, maxsplit = -1): PyList[PyStr] =
  rsplit_whitespace(pystr, maxsplit=maxsplit)
