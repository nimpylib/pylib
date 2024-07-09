
import std/macros
import ./struct_tm_decl

macro cTmToNormCall*(call; tm: Tm; kwargs: varargs[untyped]): untyped =
  result = quote do:
    `call`(
        `tm`.tm_year + 1900,
        `tm`.tm_mon + 1,
        `tm`.tm_mday,
        `tm`.tm_hour,
        `tm`.tm_min,
        `tm`.tm_sec,)
  for i in kwargs:
    result.add i
