
import std/strformat

func format*[T](self: T, spec: static[string]): string =
  ## builtins that formats at compile time
  const frmt = "{self:" & spec & "}"
  fmt frmt

func format*[T](self: T, spec: string): string =
  ## builtins
  result.formatValue self, spec
