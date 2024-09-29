

import std/math except divmod
proc assertFloatsAreIdentical(x, y: float) =
  template `<->`(a, b: bool): bool = not (a xor b)
  check (x.isnan <-> y.isnan) or
      x == y and (x != 0.0 or copySign(1.0, x) == copySign(1.0, y))

template check(c: PyComplex; r, i) =
  let nc = c
  assertFloatsAreIdentical nc.real, r
  assertFloatsAreIdentical nc.imag, i

suite "complex.__init__(str)":
  test "from str":
      check(complex("1"), 1.0, 0.0)
      check(complex("1j"), 0.0, 1.0)
      check(complex("-1"), -1.0, 0.0)
      check(complex("+1"), 1.0, 0.0)
      check(complex("1+2j"), 1.0, 2.0)
      check(complex("(1+2j)"), 1.0, 2.0)
      check(complex("(1.5+4.25j)"), 1.5, 4.25)
      check(complex("4.25+1J"), 4.25, 1.0)
      check(complex(" ( +4.25-6J )"), 4.25, -6.0)
      check(complex(" ( +4.25-J )"), 4.25, -1.0)
      check(complex(" ( +4.25+j )"), 4.25, 1.0)
      check(complex("J"), 0.0, 1.0)
      check(complex("( j )"), 0.0, 1.0)
      check(complex("+J"), 0.0, 1.0)
      check(complex("( -j)"), 0.0, -1.0)
      check(complex("1-1j"), 1.0, -1.0)
      check(complex("1J"), 0.0, 1.0)

      check(complex("1e-500"), 0.0, 0.0)
      check(complex("-1e-500j"), 0.0, -0.0)
      check(complex("1e-500+1e-500j"), 0.0, 0.0)
      check(complex("-1e-500+1e-500j"), -0.0, 0.0)
      check(complex("1e-500-1e-500j"), 0.0, -0.0)
      check(complex("-1e-500-1e-500j"), -0.0, -0.0)

      # SF bug 543840:  complex(string) accepts strings with \0
      # Fixed in 2.3.
      assertRaises(ValueError, complex, "1+1j\0j")
      assertRaises(ValueError, complex, "")
      assertRaises(ValueError, complex, "\0")
      assertRaises(ValueError, complex, "3\x009")
      assertRaises(ValueError, complex, "1+")
      assertRaises(ValueError, complex, "1+1j+1j")
      assertRaises(ValueError, complex, "--")
      assertRaises(ValueError, complex, "(1+2j")
      assertRaises(ValueError, complex, "1+2j)")
      assertRaises(ValueError, complex, "1+(2j)")
      assertRaises(ValueError, complex, "(1+2j)123")
      assertRaises(ValueError, complex, "x")
      assertRaises(ValueError, complex, "1j+2")
      assertRaises(ValueError, complex, "1e1ej")
      assertRaises(ValueError, complex, "1e++1ej")
      assertRaises(ValueError, complex, ")1+2j(")
      # the following three are accepted by Python 2.6
      assertRaises(ValueError, complex, "1..1j")
      assertRaises(ValueError, complex, "1.11.1j")
      assertRaises(ValueError, complex, "1e1.1j")

      # check whitespace processing
      assertEqual(complex("\u2003(\u20021+1j ) "), complex(1, 1))
      # Invalid unicode string
      # See bpo-34087
      assertRaises(ValueError, complex, "\u3053\u3093\u306b\u3061\u306f")

  test "negative_nans_from_string":
      assertEqual(copysign(1.0, complex("nan").real), 1.0)
      assertEqual(copysign(1.0, complex("-nan").real), -1.0)
      assertEqual(copysign(1.0, complex("-nanj").imag), -1.0)
      assertEqual(copysign(1.0, complex("-nan-nanj").real), -1.0)
      assertEqual(copysign(1.0, complex("-nan-nanj").imag), -1.0)

suite "complex":
  test "init":
    let z = complex(3.0, -4.0)
    check z.imag == -4.0
    check(complex(imag=1.5), 0.0, 1.5)
    check(complex(real=4.25, imag=1.5), 4.25, 1.5)
    check(complex(4.25, imag=1.5), 4.25, 1.5)
  test "literals":
    check 1-3'j == complex(1, -3)
    checkpoint "at compile-time"
    const c = -3-1'j
    check c.real == -3
    check c.imag == -1
  test "str":
    let z = complex(3.0, -4.0)
    check $z == "(3-4j)"
  test "op":
    let z = complex(3.0, -4.0)
    check z.conjugate() == complex(3.0, 4.0)
    check abs(z) == 5.0

suite "complex.__repr__":
  test "(N+nanj)":
    # there's once a bug str(complex(1, NaN)) == "(1nanj)"
  
    for i in range(1, 4):
      assertEqual str(complex(float(i), NaN)), "(" + str(i) + "+nanj)"
  test "real == 0.0":
    assertEqual str(complex(0.0, NaN)),  "nanj"
    assertEqual str(complex(-0.0, NaN)), "(-0+nanj)"


from std/math import almostEqual

type OverflowError = OverflowDefect

suite "complex.__pow__":
  template assertAlmostEqual(a, b: float) =
    check almostEqual(a, b)
  const sys_maxsize = sizeof system.int

  def assertAlmostEqual(a, b):
      when isinstance(a, PyComplex):
          when isinstance(b, PyComplex):
              assertAlmostEqual(a.real, b.real)
              assertAlmostEqual(a.imag, b.imag)
          else:
              assertAlmostEqual(a.real, b)
              assertAlmostEqual(a.imag, 0.0)
      else:
          when isinstance(b, PyComplex):
              assertAlmostEqual(a, b.real)
              assertAlmostEqual(0.0, b.imag)
          else:
              assertAlmostEqual(a, b)
  test "CPython:test_complex.ComplexTest.test_pow":
    def test_pow():
        assertAlmostEqual(pow(1+1'j, 0+0'j), 1.0)
        assertAlmostEqual(pow(0+0'j, 2+0'j), 0.0)
        assertEqual(pow(0+0'j, 2000+0'j), 0.0'j)
        # TODO
        #assertEqual(pow(0, 0+0'j), 1.0)
        #assertEqual(pow(-1, 0+0'j), 1.0)

        when not NimHasBindOverloadSymBugForComplexPow:
          assertRaises(ZeroDivisionError, pow, 0+0'j, 1'j)
          assertRaises(OverflowError, pow, 1e200+1'j, 1e200+1'j)
          assertRaises(ZeroDivisionError, pow, 0+0'j, -1000)
        assertAlmostEqual(pow(1'j, -1), 1/1'j)
        assertAlmostEqual(pow(1'j, 200), complex(1))
        #assertRaises(ValueError, pow, 1+1'j, 1+1'j, 1+1'j)
        #assertRaises(TypeError, pow, 1'j, None)
        #assertRaises(TypeError, pow, None, 1'j)
        #assertAlmostEqual(pow(1'j, 0.5), 0.7071067811865476+0.7071067811865475'j)

        a = 3.33+4.43'j
        c1 = complex(1)
        assertEqual(a ** 0'j, c1)
        assertEqual(a ** (0.0+0.0'j), c1)  ## NOTE: `a ** 0.0+0.0'J` will cause compile error

        assertEqual(3'j ** 0'j, c1)
        assertEqual(3'j ** 0, c1)

        try:
            discard 0'j ** a
            fail() # "should fail 0.0 to negative or complex power")
        except ZeroDivisionError:
            discard

        try:
            discard 0'j ** (3-2'j)
            fail()  # "should fail 0.0 to negative or complex power")
        except ZeroDivisionError:
            discard

        # The following is used to exercise certain code paths
        assertEqual(a ** 105, a ** 105)
        assertEqual(a ** -105, a ** -105)
        assertEqual(a ** -30, a ** -30)

        assertEqual(0.0'j ** 0, c1)

        b = 5.1+2.3'j
        #assertRaises(ValueError, pow, a, b, 0)

        # Check some boundary conditions; some of these used to invoke
        # undefined behaviour (https://bugs.python.org/issue44698). We're
        # not actually checking the results of these operations, just making
        # sure they don't crash (for example when using clang's
        # UndefinedBehaviourSanitizer).
        values = [sys_maxsize, sys_maxsize+1, sys_maxsize-1,
                  -sys_maxsize, -sys_maxsize+1, -sys_maxsize+1]
        for real in values:
            for imag in values:
                #with subTest(real=real, imag=imag):
                    c = complex(real, imag)
                    try:
                        discard c ** real
                    except OverflowError:
                        discard
                    try:
                        _ = c ** c
                    except OverflowError:
                        discard
    test_pow()

  test "with small integer exponents":
    def test_pow_with_small_integer_exponents():
        # Check that small integer exponents are handled identically
        # regardless of their type.
        values = [
            complex(5.0, 12.0),
            complex(5.0e100, 12.0e100),
            complex(-4.0, INF),
            complex(INF, 0.0),
        ]
        exponents = [-19, -5, -3, -2, -1, 0, 1, 2, 3, 5, 19]
        
        emp0 = complex(0)
        int_pow = emp0
        float_pow = int_pow
        complex_pow = int_pow
        for value in values:
            for exponent in exponents:
                #with subTest(value=value, exponent=exponent):
                    try:
                        int_pow = value**exponent
                    except OverflowError:
                        int_pow = emp0
                    try:
                        float_pow = value**float(exponent)
                    except OverflowError:
                        float_pow = emp0
                    try:
                        complex_pow = value**complex(exponent)
                    except OverflowError:
                        complex_pow = emp0
                    template assertComplexEqual(a, b) =
                      if a.real.isNaN or b.real.isNaN or a.imag.isNaN or b.imag.isNaN:
                        assertEqual(str(a), str(b))
                        if str(a) != str(b):
                          echo value
                          echo exponent
                      else:
                        assertEqual(a, b)
                        if (a) != (b):
                          echo value
                          echo exponent
                    assertComplexEqual(float_pow, int_pow)
                    assertComplexEqual(complex_pow, int_pow)

    test_pow_with_small_integer_exponents()
