
import ./strimpl
import ../stringlib/format as pyformatlib
import std/macros

template format*[T](value: T, format_spec: PyStr = ""): PyStr =
  ## builtins.format
  str pyformatlib.format(value, $format_spec)

template format*(s: PyStr, argKw: varargs[untyped]): PyStr =
  ## str.format
  ## 
  ## NOTE: `s` must be static (e.g. a str literal), 
  ## as this will be expanded at compile-time
  str pyformat($s, argKw)

