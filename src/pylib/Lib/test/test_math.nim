## Given many funcs in math wraps std/math,
##  we only tests others

import ./import_utils
importPyLib math
importPyLib sys
pyimport unittest
from std/unittest import suiteStarted,  TestStatus, testStarted, suiteEnded, checkpoint, fail, TestResult,
  suite, test, check, expect

const
  NINF = NegInf
const
  # cached
  F_INF = Inf
  F_NINF = NegInf
  F_NAN = NaN

suite "gamma":
  test "gamma(-integer)":
    for i in (-1)..(-1000):
      check isnan gamma float i
      # XXX: TODO: PY-DIFF expect DomainError: discard gamma float i

suite "ldexp":
  proc test_call(): bool =
    let res = ldexp(1.5, 2)
    result = res == 6.0
    if not result:
      echo "ldexp(", 1.5, ", ", 2, "), expected ", 6.0, " got ", res
  check test_call()
  const res = test_call()
  check res

suite "sumprod":
  test "array":
    let a = [1,2,3]
    check 14.0 == sumprod(a,a)

  test "CPython:test_math.testSumProd":
    template sumprod(a, b): untyped = math.sumprod(a, b)
    def testSumProd():

#[ TODOL Decimal is not implemented (as of 0.9.3)
        Decimal = decimal.Decimal
        Fraction = fractions.Fraction
]#

        # Core functionality
        #assertEqual(sumprod(iter([10, 20, 30]), (1, 2, 3)), 140)
        assertEqual(sumprod([1.5, 2.5], [3.5, 4.5]), 16.5)
        empI = [0]
        assertEqual(sumprod(empI, empI), 0)
        assertEqual(sumprod([-1.0], [1.0]), -1)
        assertEqual(sumprod([1], [-1]), -1)


#[ : nim is static-typed
        # Type preservation and coercion
        for v in [
            (10, 20, 30),
            (1.5, -2.5),
            (Fraction(3, 5), Fraction(4, 5)),
            (Decimal(3.5), Decimal(4.5)),
            (2.5, 10),             # float/int
            (2.5, Fraction(3, 5)), # float/fraction
            (25, Fraction(3, 5)),  # int/fraction
            (25, Decimal(4.5)),    # int/decimal
        ]:
            for p, q in [(v, v), (v, v[::-1])]:
                with subTest(p=p, q=q):
                    expected = sum(p_i * q_i for p_i, q_i in zip(p, q, strict=True))
                    actual = sumprod(p, q)
                    assertEqual(expected, actual)
                    assertEqual(type(expected), type(actual))
]#

        # Bad arguments
        check not compiles(sumprod())               # No args
        check not compiles(sumprod([0]))           # One arg
        check not compiles(sumprod([0], [0], [0]))   # Three args
        check not compiles(sumprod(None, [10]))   # Non-iterable
        check not compiles(sumprod([10], None))   # Non-iterable
        check not compiles(sumprod(['x'], [1.0]))

        # Uneven lengths
        expect(ValueError): discard sumprod([10, 20], [30])
        expect(ValueError): discard sumprod([10], [20, 30])

        # Overflows
#[ : nim's int overflow
        assertEqual(sumprod([10**20], [1]), 10**20)
        assertEqual(sumprod([1], [10**20]), 10**20)

        assertRaises(OverflowError, sumprod, [10**1000], [1.0])
        assertRaises(OverflowError, sumprod, [1.0], [10**1000])
]#

        assertEqual(sumprod([10**3], [10**3]), 10**6)
  

# SYNTAX-BUG: assertEqual(sumprod([10**7]*10**5, [10**7]*10**5), 10**19)

#[ : static-typed
        type ARuntimeError = object of CatchableError
        # Error in iterator
        def raise_after(n):
            for i in range(n):
                yield i
            raise ARuntimeError
        with assertRaises(ARuntimeError):
            sumprod(range(10), raise_after(5))
        with assertRaises(ARuntimeError):
            sumprod(raise_after(5), range(10))
]#

#[
        from test.test_iter import BasicIterClass

        assertEqual(sumprod(BasicIterClass(1), [1]), 0)
        assertEqual(sumprod([1], BasicIterClass(1)), 0)
]#

#[ : static-typed TODO
        # Error in multiplication
        type
          MultiplyType = ref object of RootObj
          BadMultiplyType = object of BadMultiplyType

        method `*`(self: MultiplyType)
        func BadMultiply: BadMultiplyType = BadMultiplyType 0
        def `*`(self: BadMultiplyType, other):
          raise ARuntimeError
        def `*`(other: auto, self: BadMultiplyType):
          raise ARuntimeError
        expect (ARuntimeError):
            sumprod([10, BadMultiply(), 30], [1, 2, 3])
        expect (ARuntimeError):
            sumprod([1, 2, 3], [10, BadMultiply(), 30])
]#


        #[
        # Error in addition
        with assertRaises(TypeError):
            sumprod(['abc', 3], [5, 10])
        with assertRaises(TypeError):
            sumprod([5, 10], ['abc', 3])
        ]#

        # Special values should give the same as the pure python recipe
        assertEqual(sumprod([10.1, math.inf], [20.2, 30.3]), math.inf)
        assertEqual(sumprod([10.1, math.inf], [math.inf, 30.3]), math.inf)
        assertEqual(sumprod([10.1, math.inf], [math.inf, math.inf]), math.inf)
        assertEqual(sumprod([10.1, -math.inf], [20.2, 30.3]), -math.inf)
        assertTrue(math.isnan(sumprod([10.1, math.inf], [-math.inf, math.inf])))
        assertTrue(math.isnan(sumprod([10.1, math.nan], [20.2, 30.3])))
        assertTrue(math.isnan(sumprod([10.1, math.inf], [math.nan, 30.3])))
        assertTrue(math.isnan(sumprod([10.1, math.inf], [20.3, math.nan])))

#[ XXX: in nimpylib, result is -7.5 instead of 0.0
        # Error cases that arose during development
        assertEqual(
          sumprod( [-5.0, -5.0, 10.0], [1.5, 4611686018427387904.0, 2305843009213693952.0] ),
          0.0)
]#
    testSumProd()

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

suite "nextafter_ulp":
  template assertEqualSign(a, b) =
    let
      sa = copysign(1.0, a)
      sb = copysign(1.0, b)
    check sa == sb
  template assertIsNaN(x) =
    check isnan(x)
  test "nextafter":
    #@requires_IEEE_754
    def test_nextafter():
        # around 2^52 and 2^63
        assertEqual(math.nextafter(4503599627370496.0, -INF),
                         4503599627370495.5)
        assertEqual(math.nextafter(4503599627370496.0, INF),
                         4503599627370497.0)
        assertEqual(math.nextafter(9223372036854775808.0, 0.0),
                         9223372036854774784.0)
        assertEqual(math.nextafter(-9223372036854775808.0, 0.0),
                         -9223372036854774784.0)

        # around 1.0
        assertEqual(math.nextafter(1.0, -INF),
                         float_fromhex("0x1.fffffffffffffp-1"))
        assertEqual(math.nextafter(1.0, INF),
                         float_fromhex("0x1.0000000000001p+0"))
        assertEqual(math.nextafter(1.0, -INF, steps=1),
                         float_fromhex("0x1.fffffffffffffp-1"))
        assertEqual(math.nextafter(1.0, INF, steps=1),
                         float_fromhex("0x1.0000000000001p+0"))
        assertEqual(math.nextafter(1.0, -INF, steps=3),
                         float_fromhex("0x1.ffffffffffffdp-1"))
        assertEqual(math.nextafter(1.0, INF, steps=3),
                         float_fromhex("0x1.0000000000003p+0"))

        # x == y: y is returned
        for steps in range(1, 5):
            assertEqual(math.nextafter(2.0, 2.0, steps=steps), 2.0)
            assertEqualSign(math.nextafter(-0.0, +0.0, steps=steps), +0.0)
            assertEqualSign(math.nextafter(+0.0, -0.0, steps=steps), -0.0)

        # around 0.0
        smallest_subnormal = sys.float_info.min * sys.float_info.epsilon
        assertEqual(math.nextafter(+0.0, INF), smallest_subnormal)
        assertEqual(math.nextafter(-0.0, INF), smallest_subnormal)
        assertEqual(math.nextafter(+0.0, -INF), -smallest_subnormal)
        assertEqual(math.nextafter(-0.0, -INF), -smallest_subnormal)
        assertEqualSign(math.nextafter(smallest_subnormal, +0.0), +0.0)
        assertEqualSign(math.nextafter(-smallest_subnormal, +0.0), -0.0)
        assertEqualSign(math.nextafter(smallest_subnormal, -0.0), +0.0)
        assertEqualSign(math.nextafter(-smallest_subnormal, -0.0), -0.0)

        # around infinity
        largest_normal = sys.float_info.max
        assertEqual(math.nextafter(INF, 0.0), largest_normal)
        assertEqual(math.nextafter(-INF, 0.0), -largest_normal)
        assertEqual(math.nextafter(largest_normal, INF), INF)
        assertEqual(math.nextafter(-largest_normal, -INF), -INF)

        # NaN
        assertIsNaN(math.nextafter(NAN, 1.0))
        assertIsNaN(math.nextafter(1.0, NAN))
        assertIsNaN(math.nextafter(NAN, NAN))

        assertEqual(1.0, math.nextafter(1.0, INF, steps=0))
        expect(ValueError):
            discard math.nextafter(1.0, INF, steps = -1)
    test_nextafter()
  test "ulp":
    const FLOAT_MAX = high float64
    #@requires_IEEE_754
    def test_ulp():
        assertEqual(math.ulp(1.0), sys.float_info.epsilon)
        # use int ** int rather than float ** int to not rely on pow() accuracy
        assertEqual(math.ulp(2.0 ** 52), 1.0)
        assertEqual(math.ulp(2.0 ** 53), 2.0)
        assertEqual(math.ulp(2.0 ** 64), 4096.0)

        # min and max
        assertEqual(math.ulp(0.0),
                         sys.float_info.min * sys.float_info.epsilon)
        assertEqual(math.ulp(FLOAT_MAX),
                         FLOAT_MAX - math.nextafter(FLOAT_MAX, -INF))

        # special cases
        assertEqual(math.ulp(INF), INF)
        assertIsNaN(math.ulp(math.nan))

        # negative number: ulp(-x) == ulp(x)
        for x in [0.0, 1.0, 2.0 ** 52, 2.0 ** 64, INF]:
            #with subTest(x=x):
                assertEqual(math.ulp(-x), math.ulp(x))
    test_ulp()

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
  when c_int is int32:
    test "large second arg":
      # the following code from CPython is only for
      # platform where c_int is int32
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
