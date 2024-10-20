##[

.. hint::
  result calculated at compile-time may a little differ those in runtime-time,
  e.g. For log1p: for i in 1..100, x = float(i), the following are results that differs each other:

x = 2.0
========
c_log1p(x) = 1.09861228866811
ct_log1p.log1p(x) = 1.09861228866811
relative_tol = -2.021137094636221e-16

x = 13.0
========
c_log1p(x) = 2.639057329615258
ct_log1p.log1p(x) = 2.639057329615259
relative_tol = 1.682756963505621e-16

x = 47.0
========
c_log1p(x) = 3.871201010907891
ct_log1p.log1p(x) = 3.871201010907891
relative_tol = -1.147161329516994e-16

x = 73.0
========
c_log1p(x) = 4.30406509320417
ct_log1p.log1p(x) = 4.304065093204169
relative_tol = -2.063580360581673e-16


]##
from ./platformUtils import impJsOrC, clikeOr
import ./comptime/expm1 as ct_expm1
import ./comptime/log1p as ct_log1p

impJsOrC log1p, log1pf, x_native

func c_log1p[F](x: F): F{.inline.} =
  #[ from CPython/Modules/_math.h _Py_log1p:
  /*Some platforms (e.g. MacOS X 10.8, see gh-59682) supply a log1p function
but don't respect the sign of zero:  log1p(-0.0) gives 0.0 instead of
the correct result of -0.0.

To save fiddling with configure tests and platform checks, we handle the
special case of zero input directly on all platforms.*/]#
  if unlikely(x == 0.0): x  # respect its sign
  else: log1p(x_native=x)

func log1p*[F: SomeFloat](x: F): F =
  clikeOr(c_log1p(x), ct_log1p.log1p)


impJsOrC expm1, expm1f, native_x

func expm1*[F: SomeFloat](x: F): F =
  clikeOr(
    expm1(native_x=x),
    ct_expm1.expm1(x)
  )

when isMainModule:
  from std/sugar import dump
  block:
   for i in 1..100:
    let x = float i
    let
      dest = c_log1p(x)
      res = ct_log1p.log1p(x)
    if dest == res: continue

    dump x
    echo "========"
    dump c_log1p(x)
    dump ct_log1p.log1p(x)
    let relative_tol = (res - dest) / dest
    dump relative_tol
    echo ""
