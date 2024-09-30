
import std/math
from ./platformUtils import CLike

template expM(x) = export math.x

expM isnan

func n_isfinite(x: SomeFloat): bool{.used.} =
  let cls = classify(x)
  result = cls != fcInf and cls != fcNegInf and cls != fcNan

func n_isinf(x: SomeFloat): bool{.used.} =
  x == Inf or x == NegInf

when defined(js):
  func js_isfiniteImpl(x: float): bool{.importjs: "Number.isFinite(#)".}
  func js_isfinite(x: SomeFloat): bool = float(x).js_isfiniteImpl
  func js_isinf(x: SomeFloat): bool =
    not x.isnan and not x.js_isfinite

template wrap(sym, c_sym, n_sym, js_sym){.dirty.} =
  func c_sym(x: c_double|c_float): c_int{.importc: astToStr(sym), header: "<math.h>".}
  func sym(x: SomeFloat): bool =
    when nimvm: n_sym(x)
    else:
      when CLike:
        bool c_sym (when x is float32: x.c_float else: x.c_double)
      elif defined(js): js_sym x
      else: n_sym(x)

wrap isfinite, c_isfinite, n_isfinite, js_isfinite
wrap isinf, c_isinf, n_isinf, js_isinf

export isinf
export isfinite
