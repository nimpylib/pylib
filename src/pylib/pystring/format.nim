
import ./strimpl
import ../stringlib/format as pyformatlib
import std/macros
import ../version

template format*[T](value: T, format_spec: PyStr = ""): PyStr =
  ## builtins.format
  str pyformatlib.format(value, $format_spec)

template format*(s: PyStr, argKw: varargs[untyped]): PyStr =
  ## str.format
  ## 
  ## .. hint:: if `s` is static (e.g. a str literal), 
  ##   this will be expanded at compile-time; otherwise at run-time,
  ##   and exception may be raised for bad format syntax.
  ##   so using static `s` is recommended.
  bind pyformat, str
  str pyformat($s, argKw)

template format_map*(s: PyStr, map): PyStr{.pysince(3,2).} =
  bind pyformatMap, str
  str pyformatMap($s, map)
