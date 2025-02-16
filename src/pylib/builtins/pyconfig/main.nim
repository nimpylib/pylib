
from std/strutils import contains

const
  DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754* = "arm" in hostCPU  ## CPython/configure.ac


import ./util

AC_RUN_IFELSE X87_double_rounding, false:
  # ref "On IEEE 754, test should return 1 if rounding"
  # maybe following is enough, but I still put origin C code below
  import std/fenv;quit int(fegetround()==FE_TONEAREST)
#[
 Detect whether system arithmetic is subject to x87-style double
 rounding issues.  The result of this test has little meaning on non
 IEEE 754 platforms.  On IEEE 754, test should return 1 if rounding
 mode is round-to-nearest and double rounding issues are present, and
 0 otherwise.  See https://github.com/python/cpython/issues/47186 for more info.
[for x87-style double rounding], [ac_cv_x87_double_rounding],
# $BASECFLAGS may affect the result

#include <stdlib.h>
#include <math.h>
int main(void) {
    volatile double x, y, z;
    /* 1./(1-2**-53) -> 1+2**-52 (correct), 1.0 (double rounding) */
    x = 0.99999999999999989; /* 1-2**-53 */
    y = 1./x;
    if (y != 1.)
        exit(0);
    /* 1e16+2.99999 -> 1e16+2. (correct), 1e16+4. (double rounding) */
    x = 1e16;
    y = 2.99999;
    z = x + y;
    if (z != 1e16+4.)
        exit(0);
    /* both tests show evidence of double rounding */
    exit(1);
}
]#

AC_LINK_IFELSE HAVE_GCC_ASM_FOR_X87, false:
  func main =
    {.emit:"""
unsigned short cw;
__asm__ __volatile__ ("fnstcw %0" : "=m" (cw));
__asm__ __volatile__ ("fldcw %0" : : "m" (cw));
""".}
  main()

AC_LINK_IFELSE HAVE_GCC_ASM_FOR_MC68881, false:
  func main =
    var fpcr: c_uint
    {.emit: """
    __asm__ __volatile__ ("fmove.l %%fpcr,%0" : "=g" (`fpcr`));
    __asm__ __volatile__ ("fmove.l %0,%%fpcr" : : "g" (`fpcr`));
    """.}
  main()

## --- HAVE_PY_SET_53BIT_PRECISION macro ------------------------------------
#[
 The functions _Py_dg_strtod() and _Py_dg_dtoa() in Python/dtoa.c (which are
 required to support the short float repr introduced in Python 3.1) require
 that the floating-point unit that's being used for arithmetic operations on
 C doubles is set to use 53-bit precision.  It also requires that the FPU
 rounding mode is round-half-to-even, but that's less often an issue.

 If your FPU isn't already set to 53-bit precision/round-half-to-even, and
 you want to make use of _Py_dg_strtod() and _Py_dg_dtoa(), then you should:

     #define HAVE_PY_SET_53BIT_PRECISION 1

 and also give appropriate definitions for the following three macros:

 * _Py_SET_53BIT_PRECISION_HEADER: any variable declarations needed to
   use the two macros below.
 * _Py_SET_53BIT_PRECISION_START: store original FPU settings, and
   set FPU to 53-bit precision/round-half-to-even
 * _Py_SET_53BIT_PRECISION_END: restore original FPU settings

 The macros are designed to be used within a single C function: see
 Python/pystrtod.c for an example of their use.
]#


# Get and set x87 control word for gcc/x86

when HAVE_GCC_ASM_FOR_X87:
  template HAVE_PY_SET_53BIT_PRECISION*: bool = true
  
  # Functions defined in Python/pymath.c
  ## Inline assembly for getting and setting the 387 FPU control word on
  ## GCC/x86.

  ##ifdef _Py_MEMORY_SANITIZER
  #__attribute__((no_sanitize_memory))
  ##endif
  proc Py_get_387controlword: c_ushort =
    {.emit: """
    __asm__ __volatile__ ("fnstcw %0" : "=m" (`result`));
    """.}

  proc Py_set_387controlword(cw: c_ushort) =
    {.emit: """
    __asm__ __volatile__ ("fldcw %0" : : "m" (`cw`));
    """.}

  template Py_SET_53BIT_PRECISION_HEADER*{.dirty.} =
    type ControlWord = c_ushort
    var old_387controlword, new_387controlword: ControlWord
  template  Py_SET_53BIT_PRECISION_START* =
        old_387controlword = Py_get_387controlword();
        new_387controlword = (old_387controlword and not 0x0f00.ControlWord) or 0x0200
        if new_387controlword != old_387controlword:
          Py_set_387controlword(new_387controlword)
  template Py_SET_53BIT_PRECISION_END* =
        if new_387controlword != old_387controlword:
          Py_set_387controlword(old_387controlword)

# Get and set x87 control word for VisualStudio/x86.
# x87 is not supported in 64-bit or ARM.
when defined(vcc) and
    #[ && !defined(_WIN64) && !defined(_M_ARM) ]#
    defined(windows) and not defined(arm64):
  template HAVE_PY_SET_53BIT_PRECISION*: bool = true

  {.push header: "<float.h>".}
  proc c_control87_2(
    `new`, mask: c_uint; x86_cw, sse2_cw: ptr c_uint
    ): c_int{.discardable, importc: "__control87_2".}
  let
   c_MCW_PC{.importc: "_MCW_PC".},
    c_MCW_RC{.importc: "_MCW_RC".},
    c_PC_53{.importc: "_PC_53".},
    c_RC_NEAR{.importc: "_RC_NEAR".}: c_uint
  {.pop.}

  template Py_SET_53BIT_PRECISION_HEADER*{.dirty.} =
    var old_387controlword, new_387controlword, out_387controlword: c_uint
    # We use the __control87_2 function to set only the x87 control word.
    # The SSE control word is unaffected.

  template  Py_SET_53BIT_PRECISION_START* =
        c_control87_2(0, 0, old_387controlword.addr, nil)
        new_387controlword =
          (old_387controlword and not(c_MCW_PC or c_MCW_RC)) or
          (c_PC_53 or c_RC_NEAR)
        if new_387controlword != old_387controlword:
            c_control87_2(new_387controlword, c_MCW_PC or c_MCW_RC,
                          out_387controlword.addr, nil)
  template Py_SET_53BIT_PRECISION_END* =
        if new_387controlword != old_387controlword:
            c_control87_2(old_387controlword, c_MCW_PC or c_MCW_RC,
                          out_387controlword.addr, nil)


# MC68881

when HAVE_GCC_ASM_FOR_MC68881:
  template HAVE_PY_SET_53BIT_PRECISION*: bool{.redefine.} = true
  {.push redefine.}
  template Py_SET_53BIT_PRECISION_HEADER*{.dirty.} =
    var old_fpcr, new_fpcr: c_uint
  template Py_SET_53BIT_PRECISION_START* =
        asm """ "fmove.l %%fpcr,%0" : "=g" (old_fpcr) """"
        # Set double precision / round to nearest.
        new_fpcr = (old_fpcr and not 0xf0) or 0x80
        if new_fpcr != old_fpcr:
          {.emit: """
          __asm__ volatile ("fmove.l %0,%%fpcr" : : "g" (new_fpcr));
          """.}
  template Py_SET_53BIT_PRECISION_END* =
    if new_fpcr != old_fpcr:
      {.emit: """
            __asm__ volatile ("fmove.l %0,%%fpcr" : : "g" (old_fpcr));
      """.}
  {.pop.}

# Default definitions are empty
when not declared(Py_SET_53BIT_PRECISION_HEADER):
  template HAVE_PY_SET_53BIT_PRECISION*: bool = false
  template noop(name) =
    template name* = discard
  noop Py_SET_53BIT_PRECISION_HEADER
  noop Py_SET_53BIT_PRECISION_START
  noop Py_SET_53BIT_PRECISION_END

  




