
import ./common
import ./reimporter

proc rsplit_whitespace*(pystr: PyBytes, maxsplit = -1): PyList[PyBytes] =
  rsplit_whitespace(pystr, maxsplit=maxsplit)
