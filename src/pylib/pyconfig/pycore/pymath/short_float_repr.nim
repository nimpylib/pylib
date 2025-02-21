
from ../../floats import
  DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754, X87_DOUBLE_ROUNDING, HAVE_PY_SET_53BIT_PRECISION
export
  DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754, X87_DOUBLE_ROUNDING, HAVE_PY_SET_53BIT_PRECISION


const
  WORDS_BIGENDIAN* = cpuEndian == bigEndian
  WORDS_LITTLEENDIAN* =  cpuEndian == littleEndian

  # XXX: not sure if suitable:
  DOUBLE_IS_LITTLE_ENDIAN_IEEE754* = WORDS_LITTLEENDIAN
  DOUBLE_IS_BIG_ENDIAN_IEEE754* = WORDS_BIGENDIAN

##[
 ref https://nim-lang.org/docs/manual.html#types-preminusdefined-floatingminuspoint-types
 Nim's float XX shall always follows IEEE754
]##


## --- _PY_SHORT_FLOAT_REPR macro -------------------------------------------

# If we can't guarantee 53-bit precision, don't use the code
# in Python/dtoa.c, but fall back to standard code.  This
# means that repr of a float will be long (17 significant digits).
#
# Realistically, there are two things that could go wrong:
#
# (1) doubles aren't IEEE 754 doubles, or
# (2) we're on x86 with the rounding precision set to 64-bits
#     (extended precision), and we don't know how to change
#     the rounding precision.
when not DOUBLE_IS_LITTLE_ENDIAN_IEEE754 and
    not DOUBLE_IS_BIG_ENDIAN_IEEE754 and
    not DOUBLE_IS_ARM_MIXED_ENDIAN_IEEE754:
  const PY_SHORT_FLOAT_REPR = false

# Double rounding is symptomatic of use of extended precision on x86.
# If we're seeing double rounding, and we don't have any mechanism available
# for changing the FPU rounding precision, then don't use Python/dtoa.c.
when X87_DOUBLE_ROUNDING and not HAVE_PY_SET_53BIT_PRECISION:
  const PY_SHORT_FLOAT_REPR = false

when not declared(PY_SHORT_FLOAT_REPR):
  const PY_SHORT_FLOAT_REPR = true

export PY_SHORT_FLOAT_REPR
