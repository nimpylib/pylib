# import and exported via ./format
import std/strformat

template format*[T](value: T, format_spec: string = ""): string =
  ## wrapper of std/strformat `formatValue`
  bind formatValue
  var result: string
  formatValue(result, value, format_spec)
  result

func format*(value: char, format_spec: string = ""): string =
  format($value, format_spec)
