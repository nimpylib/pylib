
import std/macros
import ./struct_tm_decl

macro cTmToNormCall*(call; tm: Tm; kwargs: varargs[untyped]): untyped =
  result = quote do:
    `call`(
        `tm`.year,
        `tm`.month,
        `tm`.tm_mday,
        `tm`.tm_hour,
        `tm`.tm_min,
        `tm`.tm_sec,)
  for i in kwargs:
    result.add i
