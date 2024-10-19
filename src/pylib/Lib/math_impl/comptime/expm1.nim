##[
 compiletime/expm1.nim 10/19/2024:
    - translated from and combine s_expm1.c and s_expm1f.c
    - Also, some formula in the following doc used to have some tabs for indent,
        I replaced them with spaces.

 ---

 @(#)s_expm1.c 1.5 04/04/22
 And s_expm1f.c

 ====================================================
 Copyright (C) 2004 by Sun Microsystems, Inc. All rights reserved.
 Copyright (C) 2024 by litlighilit. All rights reserved.

 Permission to use, copy, modify, and distribute this
 software is freely granted, provided that this notice
 is preserved.
 ====================================================
 expm1(x)
 Returns exp(x)-1, the exponential of x minus 1.

 Method
   1. Argument reduction:
    Given x, find r and integer k such that

               x = k*ln2 + r,  |r| <= 0.5*ln2 ~ 0.34658

      Here a correction term c will be computed to compensate
    the error in r when rounded to a floating-point number.

   2. Approximating expm1(r) by a special rational function on
    the interval [0,0.34658]:
    Since
        r*(exp(r)+1)/(exp(r)-1) = 2+ r^2/6 - r^4/360 + ...
    we define R1(r*r) by
        r*(exp(r)+1)/(exp(r)-1) = 2+ r^2/6 * R1(r*r)
    That is,
        R1(r**2) = 6/r *((exp(r)+1)/(exp(r)-1) - 2/r)
             = 6/r * ( 1 + 2.0*(1/(exp(r)-1) - 1/r))
             = 1 - r^2/60 + r^4/2520 - r^6/100800 + ...
      We use a special Remes algorithm on [0,0.347] to generate
     a polynomial of degree 5 in r*r to approximate R1. The
    maximum error of this polynomial approximation is bounded
    by 2**-61. In other words,
        R1(z) ~ 1.0 + Q1*z + Q2*z**2 + Q3*z**3 + Q4*z**4 + Q5*z**5
    where Q1  =  -1.6666666666666567384E-2,
          Q2  =   3.9682539681370365873E-4,
          Q3  =  -9.9206344733435987357E-6,
          Q4  =   2.5051361420808517002E-7,
          Q5  =  -6.2843505682382617102E-9;
      (where z=r*r, and the values of Q1 to Q5 are listed below)
    with error bounded by
        |                  5           |     -61
        | 1.0+Q1*z+...+Q5*z   -  R1(z) | <= 2
        |                              |
    
    expm1(r) = exp(r)-1 is then computed by the following
     specific way which minimize the accumulation rounding error:
                           2     3
                          r     r    [ 3 - (R1 + R1*r/2)  ]
          expm1(r) = r + --- + --- * [--------------------]
                          2     2    [ 6 - r*(3 - R1*r/2) ]
    
    To compensate the error in the argument reduction, we use
        expm1(r+c) = expm1(r) + c + expm1(r)*c
               ~ expm1(r) + c + r*c
    Thus c+r*c will be added in as the correction terms for
    expm1(r+c). Now rearrange the term to avoid optimization
     screw up:
                    (      2                                    2 )
                    ({  ( r    [ R1 -  (3 - R1*r/2) ]  )  }    r  )
     expm1(r+c)~r - ({r*(--- * [--------------------]-c)-c} - --- )
                    ({  ( 2    [ 6 - r*(3 - R1*r/2) ]  )  }    2  )
                    (                                             )
        
           = r - E
   3. Scale back to obtain expm1(x):
    From step 1, we have
       expm1(x) = either 2^k*[expm1(r)+1] - 1
            = or     2^k*[expm1(r) + (1-2^-k)]
   4. Implementation notes:
    (A). To save one multiplication, we scale the coefficient Qi
         to Qi*2^i, and replace z by (x^2)/2.
    (B). To achieve maximum accuracy, we compute expm1(x) by
      (i)   if x < -56*ln2, return -1.0, (raise inexact if x!=inf)
      (ii)  if k=0, return r-E
      (iii) if k=-1, return 0.5*(r-E)-0.5
      (iv)    if k=1 if r < -0.25, return 2*((r+0.5)- E)
                      else         return  1.0+2.0*(r-E);
      (v)   if (k<-2||k>56) return 2^k(1-(E-r)) - 1 (or exp(x)-1)
      (vi)  if k <= 20, return 2^k((1-2^-k)-(E-r)), else
      (vii) return 2^k(1-((E+2^-k)-r))

 Special cases:
    expm1(INF) is INF, expm1(NaN) is NaN;
    expm1(-INF) is -1, and
    for finite argument, only expm1(0)=0 is exact.

 Accuracy:
    according to an error analysis, the error is always less than
    1 ulp (unit in the last place).

 Misc. info.
    For IEEE double
        if x >  7.09782712893383973096e+02 then expm1(x) overflow

 Constants:
 The hexadecimal values are the intended ones for the following
 constants. The decimal values may be used, provided that the
 compiler will convert from decimal to binary accurately enough
 to produce the hexadecimal values shown.
]##

import ./common

#[unused:
template getHighWord(x: float): uint32 = cast[uint32](cast[uint64](x) shr 32)
template incHighWord(x: float; inc_hi) =
  let (hi, lo) = x.toWords
  x = fromWords(hi + inc_hi, lo)
]#

# NOTE: for nimvm, two step's cast is necessary


genWithBracket hugeF, 1.0e+300, 1.0e+30
genWithBracket tinyF, 1.0e-300, 1.0e-30
genWithBracket o_threshold,
    7.09782712893383973096e+02, ##  0x40862E42, 0xFEFA39EF
    8.8721679688e+01  ## 0x42b17180

const
  one = 1.0
  invln2 = 1.44269504088896338700e+00 ##  0x3ff71547, 0x652b82fe

template SET_FLOAT_WORD(u: uint32): float32 = cast[float32](u)
template SET_FLOAT_WORD(x: var float32, u: uint32) = x = SET_FLOAT_WORD(u)

proc expm1*[F: SomeFloat](x: F): F =
  const
    huge = hugeF[F]
    tiny = tinyF[F]
  const isFloat32 = F is float32
  template f2[T](f64, f32: T): T =
    when isFloat32: f32 else: f64
  template f2Do(f64; f32) =
    when isFloat32: f32 else: f64
  when isFloat32:
    var hx: uint32
    GET_FLOAT_WORD(hx, x)
    const hxLimits = [  # |x| >=
        0x4195b844u32,  #  56*ln2
        0x7f800000,     #  709.78
        0x7f800000,
    ]
    const xLimitsWhenReduce = [ # |x|
        0x3eb17218u32,      # > 0.5 ln2
        0x3F851592,         # <  1.5 ln2
    ]
    # must be template to delay evalution
    template checkNaNByHx: bool = hx > 0x7f800000
    template checkInfByHxAfterNaN: bool = hx > 0x7f800000
  else:
    var (hx, lx) = x.toWords()
    const hxLimits = [ # |x|>=
        0x4043687Au32, #  27*ln2 = 18.714...
        0x40862E42,    #  88.721...
        0x7ff00000,
    ]
    const xLimitsWhenReduce = [ # |x|
        0x3fd62e42u32,     # > 0.5 ln2
        0x3FF0A2B2         # <  1.5 ln2
    ]
    # must be template to delay evalution
    template checkNaNByHx: bool = ((hx and 0xfffff) or lx) != 0
    template checkInfByHxAfterNaN: bool = true

  let xsb = hx and 0x80000000'u32  # sign bit of x
  let xsb0 = xsb == 0
  result = if xsb0: x else: -x #  result = |x|
  hx = hx and 0x7fffffff'u32  #  high word of |x|, discard signbit

  ##  filter out huge and non-finite argument
  if hx >= hxLimits[0]:
    if hx >= hxLimits[1]:
      if hx >= hxLimits[2]:
        if checkNaNByHx:  # NaN
          return x + x
        if checkInfByHxAfterNaN:   # inf
          return if xsb0: x else: -1.0
          #  exp(+-inf)={inf,-1}
      if x > o_threshold[F]:
        return huge * huge  # overflow
    if not xsb0:
      ##  x < -56*ln2.float64 | -27*ln2.float32, return -1.0 with inexact
      if x + tiny < 0.0:  # raise inexact
        return tiny - one # return -1

  var
    c: F
    t: F
    k: int32
  template asUnsigned(x: int32): uint32 = cast[uint32](x)
  # argument reduction
  var x = x  # shallow x to make it mutable
  var hi, lo: F
  if hx > xLimitsWhenReduce[0]:
    if hx < xLimitsWhenReduce[1]:
      if xsb0:
        hi = x - ln2_hi
        lo = ln2_lo
        k = 1
      else:
        hi = x + ln2_hi
        lo = -ln2_lo
        k = -1
    else:
      k = typeof(k) invln2 * x + (if xsb0: 0.5 else: -0.5)
      t = typeof(t) k
      hi = x - t * ln2_hi
      ##  t*ln2_hi is exact here
      lo = t * ln2_lo
    x = hi - lo
    c = (hi - x) - lo
  elif hx < f2(0x3c900000, 0x33000000):
    ##  when |x|<2**-54|2**-25, return x
    t = huge + x
    ##  return x with inexact flags when x!=0
    return x - (t - (huge + x))
  else:
    k = 0
  ##  x is now in primary range
  let
    hfx = 0.5 * x
    hxs = x * hfx
    r1 = f2( #  scaled coefficients related to expm1
      polExpd0(hxs, [
        one
        ,-3.33333333333331316428e-02 #  BFA11111 111110F4
        ,1.58730158725481460165e-03  #  3F5A01A0 19FE5585
        ,-7.93650757867487942473e-05 #  BF14CE19 9EAADBB7
        ,4.00821782732936239552e-06  #  3ED0CFCA 86E65239
        ,-2.01099218183624371326e-07 #  BE8AFDB7 6E09C32D
      ]),
      polExpd0(hxs, [
        one.F
        ,-3.3333212137e-2  # -0x888868.0p-28
        ,1.5807170421e-3   # 0xcf3010.0p-33
      ]#[Domain [-0.34568, 0.34568], range ~[-6.694e-10, 6.696e-10]:
         |6 / x * (1 + 2 * (1 / (exp(x) - 1) - 1 / x)) - q(x)| < 2**-30.04
         Scaled coefficients: Qn_here = 2**n * Qn_for_q (see s_expm1.c)]#
      )
    )

  t = 3.0 - r1 * hfx
  var e = hxs * ((r1 - t) / (6.0 - x * t))
  const kShift = f2(20, 23)
  if k == 0:
    return x - (x * e - hxs)
  else:
    let twopk = f2(
      fromWords(     0x3ff00000 + (k.asUnsigned shl kShift), 0),
      SET_FLOAT_WORD(0x3f800000 + (k.asUnsigned shl kShift))
    )
    e = (x * (e - c) - c)
    e -= hxs
    if k == -1:
      return 0.5 * (x - e) - 0.5
    if k == 1:
      if x < -0.25:
        return -(2.0 * (e - (x + 0.5)))
      else:
        return one + 2.0 * (x - e)
    if k <= -2 or k > 56:
      #  suffice to return exp(x)-1
      result = one - (e - x)
      # For float64, the following is the same as:
      #  incHighWord(result, UInt(k shl 20))  #  add k to result's exponent
      if k == f2(1024, 128):
        template mul(f: F) =
          result = result * 2.0 * f
        f2Do(
            mul(0x7FE0000000000000'f64), # 0x1p+1023
            mul(0x7F000000'f32)          # 0x1p+127
        )
      else:
        result *= twopk
      return result - one
    t = one
    if k < kShift:
      f2Do(
        setHighWord(t,    0x3ff00000'u32 -  (0x200000'u32 shr k)),
        SET_FLOAT_WORD(t, 0x3f800000'u32 - (0x1000000'u32 shr k))
      )
      ##  t=1-2^-k

      result = t - (e - x)
    else:
      f2Do(
        setHighWord(t,   (0x3ff'u32 - k.asUnsigned) shl kShift),
        SET_FLOAT_WORD(t, (0x7f'u32 - k.asUnsigned) shl kShift)
      )
      ##  2^-k
      result = x - (e + t)
      result += one
    result *= twopk
    # For float64 above is the same as:
    #  incHighWord(result, UInt(k shl 20))  #  add k to result's exponent

