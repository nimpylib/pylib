##[
 compiletime/log1p.nim 10/19/2024:
    - translated from and combine s_log1p.c and s_log1pf.c

 @(#)s_log1p.c 1.3 95/01/18
 Along with:
 /* s_log1pf.c -- float version of s_log1p.c.
 * Conversion to float by Ian Lance Taylor, Cygnus Support, ian@cygnus.com.
 */

 ====================================================
 Copyright (C) 1993 by Sun Microsystems, Inc. All rights reserved.
 Copyright (C) 2024 by litlighilit. All rights reserved.

 Developed at SunSoft, a Sun Microsystems, Inc. business.
 Permission to use, copy, modify, and distribute this
 software is freely granted, provided that this notice
 is preserved.
 ====================================================

 double log1p(double x)

 Method :
   1. Argument Reduction: find k and f such that
			1+x = 2^k * (1+f),
	   where  sqrt(2)/2 < 1+f < sqrt(2) .

      Note. If k=0, then f=x is exact. However, if k!=0, then f
	may not be representable exactly. In that case, a correction
	term is need. Let u=1+x rounded. Let c = (1+x)-u, then
	log(1+x) - log(u) ~ c/u. Thus, we proceed to compute log(u),
	and add back the correction term c/u.
	(Note: when x > 2**53, one can simply return log(x))

   2. Approximation of log1p(f).
	Let s = f/(2+f) ; based on log(1+f) = log(1+s) - log(1-s)
		 = 2s + 2/3 s**3 + 2/5 s**5 + .....,
	     	 = 2s + s*R
      We use a special Reme algorithm on [0,0.1716] to generate
 	a polynomial of degree 14 to approximate R The maximum error
	of this polynomial approximation is bounded by 2**-58.45. In
	other words,
		        2      4      6      8      10      12      14
	    R(z) ~ Lp1*s +Lp2*s +Lp3*s +Lp4*s +Lp5*s  +Lp6*s  +Lp7*s
  	(the values of Lp1 to Lp7 are listed in the program)
	and
	    |      2          14          |     -58.45
	    | Lp1*s +...+Lp7*s    -  R(z) | <= 2
	    |                             |
	Note that 2s = f - s*f = f - hfsq + s*hfsq, where hfsq = f*f/2.
	In order to guarantee error in log below 1ulp, we compute log
	by
		log1p(f) = f - (hfsq - s*(hfsq+R)).
	
	3. Finally, log1p(x) = k*ln2 + log1p(f).
		 	     = k*ln2_hi+(f-(hfsq-(s*(hfsq+R)+k*ln2_lo)))
	   Here ln2 is split into two floating point number:
			ln2_hi + ln2_lo,
	   where n*ln2_hi is always exact for |n| < 2000.

 Special cases:
	log1p(x) is NaN with signal if x < -1 (including -INF) ;
	log1p(+INF) is +INF; log1p(-1) is -INF with signal;
	log1p(NaN) is that NaN with no signal.

 Accuracy:
	according to an error analysis, the error is always less than
	1 ulp (unit in the last place).

 Constants:
 The hexadecimal values are the intended ones for the following
 constants. The decimal values may be used, provided that the
 compiler will convert from decimal to binary accurately enough
 to produce the hexadecimal values shown.

 Note: Assuming log() return accurate answer, the following
 	 algorithm can be used to compute log1p(x) to within a few ULP:
	
		u = 1+x;
		if(u==1.0) return x ; else
			   return log(u)*(x/(u-1.0));

	 See HP-15C Advanced Functions Handbook, p.193.
]##

import ./common

const
  zero = 0.0

template getHighWord(x: float): uint32 = cast[uint32](cast[uint64](x) shr 32)

proc log1p*[F: SomeFloat](x: F): F =
  var hu: uint32
  const isFloat32 = F is float32
  template f2[T](f64, f32: T): T =
    when isFloat32: f32 else: f64

  when isFloat32:
    const twoX = 3.355443200e+07  ## two25
  else:
    const twoX = 1.80143985094819840000e+16 ##  two54 43500000 00000000
  let hx = f2(getHighWord(x), GET_FLOAT_WORD(x))
  ##  high word of x
  let ax = hx and 0x7fffffff
  var
    k: typeof(hu) = 1
    f: F
  if hx < f2(0x3FDA827A, 0x3ed413d0):  # 1+x < sqrt(2)+
    ##  x < 0.41422
    if ax >= f2(0x3ff00000, 0x3f800000):  # x <= -1.0
      if x == -1.0:
        return -(twoX / zero)  ## log1p(-1) = +inf
      else:
        return (x - x) / (x - x) ##  log1p(x<-1)=NaN
    if ax < f2(0x3e200000, 0x38000000):   ##  |x| < 2**-{29,15}
      if twoX + x > zero and ax < f2(0x3c900000, 0x33800000):  ## |x| < 2**-{54,24}
        return x
      else:
        return x - x * x * 0.5
    if hx > 0 or hx <= f2(0xbfd2bec3'u32, 0xbe95f619'u32):
      k = 0
      f = x
      hu = 1
  if hx >= f2(0x7ff00000, 0x7f800000):
    return x + x
  var c: F
  if k != 0:
    var u: F
    if hx < f2(0x43400000, 0x5a000000):
      u = 1.0 + x
      hu = getHighWord(u)
      ##  high word of u
      k = f2(
        (hu shr 20) - 1023, 
        (hu shr 23) - 127
      )
      ##  correction term
      c = if (k > 0): 1.0 - (u - x) else: x - (u - 1.0)
      c = c / u
    else:
      u = x
      hu = getHighWord(u)
      ##  high word of u
      k = f2(
        (hu shr 20) - 1023, 
        (hu shr 23) - 127
      )
      c = 0
    hu = hu and f2(0x000fffff, 0x3504f4)
    if hu < f2(0x6a09e, 0x3504f4): # u < sqrt(2)
      setHighWord(u, hu or f2(0x3ff00000,0x3f800000))  #  normalize u
    else:
      k += 1
      setHighWord(u, hu or f2(0x3fe00000, 0x3f000000))   #  normalize u/2
      hu = (0x00100000 - hu) shr 2
    f = u - 1.0
  var hfsq = 0.5 * f * f
  if hu == 0:
    ##  |f| < 2**-20
    if f == zero:
      if k == 0:
        return zero
      else:
        c += k.F * ln2_lo
        return k.F * ln2_hi + c
    let R = hfsq * (1.0 - 0.66666666666666666 * f)
    if k == 0:
      return f - R
    else:
      return k.F * ln2_hi - ((R - (k.F * ln2_lo + c)) - f)
  let
    s = f / (2.0 + f)
    z = s * s
  let R = polExpd0(z, [0
, 6.666666666666735130e-01 #  3FE55555 55555593
, 3.999999999940941908e-01 #  3FD99999 9997FA04
, 2.857142874366239149e-01 #  3FD24924 94229359
, 2.222219843214978396e-01 #  3FCC71C5 1D8E78AF
, 1.818357216161805012e-01 #  3FC74664 96CB03DE
, 1.531383769920937332e-01 #  3FC39A09 D078C69F
, 1.479819860511658591e-01 #  3FC2F112 DF3E5244
  ])
  if k == 0:
    return f - (hfsq - s * (hfsq + R))
  else:
    return k.F * ln2_hi - ((hfsq - (s * (hfsq + R) + (k.F * ln2_lo + c))) - f)


when isMainModule:
  from std/math import ln
  from std/sugar import dump
  static:
   for i in 1..100:
    let x = float i
    if log1p(x) == ln(x+1): continue
    dump x
    dump ln(1+x)
    dump log1p(x)
