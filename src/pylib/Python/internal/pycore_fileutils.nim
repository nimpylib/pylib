
import std/strutils

type
  Py_error_handler* = enum
    Py_ERROR_UNKNOWN = "unknown"
    Py_ERROR_STRICT = "strict"
    Py_ERROR_SURROGATEESCAPE = "surrogateescape"
    Py_ERROR_REPLACE = "replace"
    Py_ERROR_IGNORE = "ignore"
    Py_ERROR_BACKSLASHREPLACE = "backslashreplace"
    Py_ERROR_SURROGATEPASS = "surrogatepass"
    Py_ERROR_XMLCHARREFREPLACE = "xmlcharrefreplace"
    Py_ERROR_OTHER = "other"

proc Py_GetErrorHandler*(errors: string): Py_error_handler =
  if errors == "unknown": result = Py_ERROR_OTHER
  else: result = parseEnum(errors, Py_ERROR_OTHER)

