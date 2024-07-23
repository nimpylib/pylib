## Given many funcs in math wraps std/math,
##  we only tests others

import ./import_utils
importTestPyLib math


const
  NINF = NegInf
const
  # cached
  F_INF = float("inf")
  F_NINF = float("-inf")
  F_NAN = float("nan")

suite "constants":
  test "nan":
    # `math.nan` must be a quiet NaN with positive sign bit
    check (isnan(math.nan))
    check (copysign(1.0, nan) == 1.0)
  test "inf":
    check:
      isinf(inf)
      inf > 0.0
      inf == F_INF
      -inf == F_NINF

suite "classify":
  # test "isnan": discard # isnan is alias of that in std/math
  test "isinf":
    check (isinf(F_INF))
    check (isinf(F_NINF))
    check (isinf(1E400))
    check (isinf(-1E400))
    check not (isinf(F_NAN))
    check not (isinf(0.0))
    check not (isinf(1.0))
  test "isfinite":
    check:
      isfinite(0.0)
      isfinite(-0.0)
      isfinite(1.0)
      isfinite(-1.0)
      not (isfinite(F_NAN))
      not (isfinite(F_INF))
      not (isfinite(F_NINF))

suite "ldexp":
  test "static":
    const f = ldexp(1.0, 2)
    static: assert f == 4.0, $f
  test "small":
    check:
      ldexp(0.0, 1) == 0
      ldexp(1.0, 1) == 2
      ldexp(1.0, -1) == 0.5
      ldexp(-1.0, 1) == -2
  test "non-normal first arg":
    check:
      ldexp(INF, 30) == INF
      ldexp(NINF, -213) == NINF
      isnan(ldexp(NAN, 0))
  test "large second arg":
    for f in [1e5, 1e10]:
      let n = int(f)
      check:
        ldexp(INF, -n) ==  INF
        ldexp(NINF, -n) ==  NINF
        ldexp(1.0, -n) ==  0.0
        ldexp(-1.0, -n) ==  -0.0
        ldexp(0.0, -n) ==  0.0
        ldexp(-0.0, -n) ==  -0.0
        isnan(math.ldexp(NAN, -n))
      expect OverflowDefect: discard ldexp(1.0, n)
      expect OverflowDefect: discard ldexp(-1.0, n)
      check:
        ldexp(0.0, n) == 0.0
        ldexp(-0.0, n) == -0.0
        ldexp(INF, n) == INF
        ldexp(NINF, n) == NINF
        isnan(ldexp(NAN, n))
