
import ../version
import ./stmt/[pydef, tonim]
export parsePyBody, parsePyBodyWithDoc, parsePyExpr

const PyVer = (PyMajor, PyMinor)
template sincePy(maj, min): bool = PyVer >= (maj, min)
const
  PySignatureSupportGenerics* = sincePy(3, 12)
  PyDedentDocString* = sincePy(3, 13)
  PyNoParnMultiExecInExcept* = sincePy(3, 14)

func parserWithDefCfg*: PyAsgnRewriter =
  bind PyAsgnRewriter, parsePyBody, parsePyBodyWithDoc
  static: assert PyAsgnRewriter is PySyntaxProcesser
  newPyAsgnRewriter(PySignatureSupportGenerics, PyDedentDocString,
    PyNoParnMultiExecInExcept,
  )
