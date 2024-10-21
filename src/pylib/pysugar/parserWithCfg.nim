
import ../version
import ./stmt/[pydef, tonim]
export parsePyBody, parsePyBodyWithDoc

const
  PySignatureSupportGenerics* = (PyMajor, PyMinor) >= (3, 12)
  PyDedentDocString* = (PyMajor, PyMinor) >= (3, 13)

func parserWithDefCfg*: PyAsgnRewriter =
  bind PyAsgnRewriter, parsePyBody, parsePyBodyWithDoc
  static: assert PyAsgnRewriter is PySyntaxProcesser
  newPyAsgnRewriter(PySignatureSupportGenerics, PyDedentDocString)
