##[
  The implementation uses [Horner's rule](
    https://www.geeksforgeeks.org/horners-method-polynomial-evaluation/)
      for more efficient computation.
]##

func polevl*[F](x: F, coef: openArray[F], N = coef.high): F =
  ##[
```
  Evaluates polynomial of degree N:
  
                      2          N
  y  =  C  + C x + C x  +...+ C x
         0    1     2          N
  
  Coefficients are stored in reverse order:
  
  coef[0] = C  , ..., coef[N] = C  .
              N                   0
```
  ]## 
  result = coef[0]
  for i in 1..N:
    result = result * x  +  coef[i];

import std/macros
macro polExpd*[F](x: F, coef: untyped): F =
  ## expand polynomial with coef literal
  ##  as inline expression.
  ##
  ## `coef` shall be literal of a serials of `F` surrounded by
  ## brackets, curly braces or paratheses
  runnableExamples:
    assert 1.0*3.0+2.0 == polExpd(1.0, (3.0, 2.0))
 
  expectKind coef, {nnkBracket, nnkCurly, nnkTupleConstr}
  result = coef[0]
  for i in 1..<coef.len:
    # res = res * x + coef[i]
    result = infix(
        infix(result, "*", x),
        "+",
        coef[i]);

macro polExpd0*[F](x: F, rcoef: untyped): F =
  ## the same as `polExpd` except that `rcoef` is reversed:
  ## `rcoef[0]` is the `C_0` constant (a.k.a. muliplied by `x^0`)
  expectKind rcoef, {nnkBracket, nnkCurly, nnkTupleConstr}
  let hi = rcoef.len - 1
  result = rcoef[hi]
  for i in countdown(hi-1, 0):
    # res = res * x + coef[i]
    result = infix(
        infix(result, "*", x),
        "+",
        rcoef[i]);

func p1evl*[F](x: F, coef: openArray[F], N = coef.high-1): F =
  ##[ Evaluate polynomial when coefficient of x  is 1.0.
  Otherwise same as polevl.]##
  polevl(x, coef, N)
