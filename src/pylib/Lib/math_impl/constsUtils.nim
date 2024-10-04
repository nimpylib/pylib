

template genBody(F, v32, v64): untyped =
  when F is float64: v64
  else: v32

template genWithArg*(sym, v32, v64){.dirty.} =
  bind genBody
  template sym*[F](_: typedesc[F]): F = genBody(F, v32, v64)

template genWithBracket*(sym, v32, v64, Ret){.dirty.} =
  bind genBody
  template sym*[F]: Ret = genBody(F, v32, v64)

template genWithBracket*(sym, v32, v64) =
  bind genWithBracket
  genWithBracket(sym, v32, v64, untyped)
