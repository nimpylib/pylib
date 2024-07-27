
import std/math as std_math
import std/random as std_random

from pylib/Lib/math import ldexp

randomize()


template fromHex(s: string): float =
  float_fromhex(s)
template toHex(f: float): string = f.hex()

const
    MAX = fromHex("0x.fffffffffffff8p+1024")  # max normal
    MIN = fromHex("0x1p-1022")                # min normal
    TINY = fromHex("0x0.0000000000001p-1022") # min subnormal
    EPS = fromHex("0x0.0000000000001p0") # diff between 1.0 and next float up

proc identical(x, y: float) =
    if x.isnan or y.isnan:
        check x.isnan == y.isnan
        return
    if x == y and (x != 0.0 or copySign(1.0, x)):
        return
    debugEcho repr(x) & " not identical to " & repr(y)
    debugEcho x.hex() & " not identical to " & y.hex()
    #let pos = instantiationInfo(index = -1) # no use considering this file will be included
    #debugEcho f"at {pos.filename}({pos.line},{pos.column})"
    fail()

suite "float.fromhex":
    test "literals":
        # two spellings of infinity, with optional signs; case-insensitive
        identical(fromHex("inf"), INF)
        identical(fromHex("+Inf"), INF)
        identical(fromHex("-INF"), -INF)
        identical(fromHex("iNf"), INF)
        identical(fromHex("Infinity"), INF)
        identical(fromHex("+INFINITY"), INF)
        identical(fromHex("-infinity"), -INF)
        identical(fromHex("-iNFiNitY"), -INF)
    test "nans":
        # nans with optional sign; case insensitive
        identical(fromHex("nan"), NAN)
        identical(fromHex("+NaN"), NAN)
        identical(fromHex("-NaN"), NAN)
        identical(fromHex("-nAN"), NAN)
    test "some values":
        # variations in input format
        identical(fromHex("1"), 1.0)
        identical(fromHex("+1"), 1.0)
        identical(fromHex("1."), 1.0)
        identical(fromHex("1.0"), 1.0)
        identical(fromHex("1.0p0"), 1.0)
        identical(fromHex("01"), 1.0)
        identical(fromHex("01."), 1.0)
        identical(fromHex("0x1"), 1.0)
        identical(fromHex("0x1."), 1.0)
        identical(fromHex("0x1.0"), 1.0)
        identical(fromHex("+0x1.0"), 1.0)
        identical(fromHex("0x1p0"), 1.0)
        identical(fromHex("0X1p0"), 1.0)
        identical(fromHex("0X1P0"), 1.0)
        identical(fromHex("0x1P0"), 1.0)
        identical(fromHex("0x1.p0"), 1.0)
        identical(fromHex("0x1.0p0"), 1.0)
        identical(fromHex("0x.1p4"), 1.0)
        identical(fromHex("0x.1p04"), 1.0)
        identical(fromHex("0x.1p004"), 1.0)
        identical(fromHex("0x1p+0"), 1.0)
        identical(fromHex("0x1P-0"), 1.0)
        identical(fromHex("+0x1p0"), 1.0)
        identical(fromHex("0x01p0"), 1.0)
        identical(fromHex("0x1p00"), 1.0)
        identical(fromHex(" 0x1p0 "), 1.0)
        identical(fromHex("\n 0x1p0"), 1.0)
        identical(fromHex("0x1p0 \t"), 1.0)
        identical(fromHex("0xap0"), 10.0)
        identical(fromHex("0xAp0"), 10.0)
        identical(fromHex("0xaP0"), 10.0)
        identical(fromHex("0xAP0"), 10.0)
        identical(fromHex("0xbep0"), 190.0)
        identical(fromHex("0xBep0"), 190.0)
        identical(fromHex("0xbEp0"), 190.0)
        identical(fromHex("0XBE0P-4"), 190.0)
        identical(fromHex("0xBEp0"), 190.0)
        identical(fromHex("0xB.Ep4"), 190.0)
        identical(fromHex("0x.BEp8"), 190.0)
        identical(fromHex("0x.0BEp12"), 190.0)

        # moving the point around
        const pi = fromHex("0x1.921fb54442d18p1")
        identical(fromHex("0x.006487ed5110b46p11"), pi)
        identical(fromHex("0x.00c90fdaa22168cp10"), pi)
        identical(fromHex("0x.01921fb54442d18p9"), pi)
        identical(fromHex("0x.03243f6a8885a3p8"), pi)
        identical(fromHex("0x.06487ed5110b46p7"), pi)
        identical(fromHex("0x.0c90fdaa22168cp6"), pi)
        identical(fromHex("0x.1921fb54442d18p5"), pi)
        identical(fromHex("0x.3243f6a8885a3p4"), pi)
        identical(fromHex("0x.6487ed5110b46p3"), pi)
        identical(fromHex("0x.c90fdaa22168cp2"), pi)
        identical(fromHex("0x1.921fb54442d18p1"), pi)
        identical(fromHex("0x3.243f6a8885a3p0"), pi)
        identical(fromHex("0x6.487ed5110b46p-1"), pi)
        identical(fromHex("0xc.90fdaa22168cp-2"), pi)
        identical(fromHex("0x19.21fb54442d18p-3"), pi)
        identical(fromHex("0x32.43f6a8885a3p-4"), pi)
        identical(fromHex("0x64.87ed5110b46p-5"), pi)
        identical(fromHex("0xc9.0fdaa22168cp-6"), pi)
        identical(fromHex("0x192.1fb54442d18p-7"), pi)
        identical(fromHex("0x324.3f6a8885a3p-8"), pi)
        identical(fromHex("0x648.7ed5110b46p-9"), pi)
        identical(fromHex("0xc90.fdaa22168cp-10"), pi)
        identical(fromHex("0x1921.fb54442d18p-11"), pi)
        # ...
        identical(fromHex("0x1921fb54442d1.8p-47"), pi)
        identical(fromHex("0x3243f6a8885a3p-48"), pi)
        identical(fromHex("0x6487ed5110b46p-49"), pi)
        identical(fromHex("0xc90fdaa22168cp-50"), pi)
        identical(fromHex("0x1921fb54442d18p-51"), pi)
        identical(fromHex("0x3243f6a8885a30p-52"), pi)
        identical(fromHex("0x6487ed5110b460p-53"), pi)
        identical(fromHex("0xc90fdaa22168c0p-54"), pi)
        identical(fromHex("0x1921fb54442d180p-55"), pi)
    test "overflow":
        # results that should overflow...
        expect(OverflowDefect): discard fromHex "-0x1p1024"
        expect(OverflowDefect): discard fromHex "0x1p+1025"
        expect(OverflowDefect): discard fromHex "+0X1p1030"
        expect(OverflowDefect): discard fromHex "-0x1p+1100"
        expect(OverflowDefect): discard fromHex "0X1p123456789123456789"
        expect(OverflowDefect): discard fromHex "+0X.8p+1025"
        expect(OverflowDefect): discard fromHex "+0x0.8p1025"
        expect(OverflowDefect): discard fromHex "-0x0.4p1026"
        expect(OverflowDefect): discard fromHex "0X2p+1023"
        expect(OverflowDefect): discard fromHex "0x2.p1023"
        expect(OverflowDefect): discard fromHex "-0x2.0p+1023"
        expect(OverflowDefect): discard fromHex "+0X4p+1022"
        expect(OverflowDefect): discard fromHex "0x1.ffffffffffffffp+1023"
        expect(OverflowDefect): discard fromHex "-0X1.fffffffffffff9p1023"
        expect(OverflowDefect): discard fromHex "0X1.fffffffffffff8p1023"
        expect(OverflowDefect): discard fromHex "+0x3.fffffffffffffp1022"
        expect(OverflowDefect): discard fromHex "0x3fffffffffffffp+970"
        expect(OverflowDefect): discard fromHex "0x10000000000000000p960"
        expect(OverflowDefect): discard fromHex "-0Xffffffffffffffffp960"

        # ...and those that round to +-max float
        identical(fromHex("+0x1.fffffffffffffp+1023"), MAX)
        identical(fromHex("-0X1.fffffffffffff7p1023"), -MAX)
        identical(fromHex("0X1.fffffffffffff7fffffffffffffp1023"), MAX)        
    test "zeros and underflow":
        # zeros
        identical(fromHex("0x0p0"), 0.0)
        identical(fromHex("0x0p1000"), 0.0)
        identical(fromHex("-0x0p1023"), -0.0)
        identical(fromHex("0X0p1024"), 0.0)
        identical(fromHex("-0x0p1025"), -0.0)
        identical(fromHex("0X0p2000"), 0.0)
        identical(fromHex("0x0p123456789123456789"), 0.0)
        identical(fromHex("-0X0p-0"), -0.0)
        identical(fromHex("-0X0p-1000"), -0.0)
        identical(fromHex("0x0p-1023"), 0.0)
        identical(fromHex("-0X0p-1024"), -0.0)
        identical(fromHex("-0x0p-1025"), -0.0)
        identical(fromHex("-0x0p-1072"), -0.0)
        identical(fromHex("0X0p-1073"), 0.0)
        identical(fromHex("-0x0p-1074"), -0.0)
        identical(fromHex("0x0p-1075"), 0.0)
        identical(fromHex("0X0p-1076"), 0.0)
        identical(fromHex("-0X0p-2000"), -0.0)
        identical(fromHex("-0x0p-123456789123456789"), -0.0)
    test "round-half-even":
        identical(fromHex("0x1p-1076"), 0.0)
        identical(fromHex("0X2p-1076"), 0.0)
        identical(fromHex("0X3p-1076"), TINY)
        identical(fromHex("0x4p-1076"), TINY)
        identical(fromHex("0X5p-1076"), TINY)
        identical(fromHex("0X6p-1076"), 2*TINY)
        identical(fromHex("0x7p-1076"), 2*TINY)
        identical(fromHex("0X8p-1076"), 2*TINY)
        identical(fromHex("0X9p-1076"), 2*TINY)
        identical(fromHex("0xap-1076"), 2*TINY)
        identical(fromHex("0Xbp-1076"), 3*TINY)
        identical(fromHex("0xcp-1076"), 3*TINY)
        identical(fromHex("0Xdp-1076"), 3*TINY)
        identical(fromHex("0Xep-1076"), 4*TINY)
        identical(fromHex("0xfp-1076"), 4*TINY)
        identical(fromHex("0x10p-1076"), 4*TINY)
        identical(fromHex("-0x1p-1076"), -0.0)
        identical(fromHex("-0X2p-1076"), -0.0)
        identical(fromHex("-0x3p-1076"), -TINY)
        identical(fromHex("-0X4p-1076"), -TINY)
        identical(fromHex("-0x5p-1076"), -TINY)
        identical(fromHex("-0x6p-1076"), -2*TINY)
        identical(fromHex("-0X7p-1076"), -2*TINY)
        identical(fromHex("-0X8p-1076"), -2*TINY)
        identical(fromHex("-0X9p-1076"), -2*TINY)
        identical(fromHex("-0Xap-1076"), -2*TINY)
        identical(fromHex("-0xbp-1076"), -3*TINY)
        identical(fromHex("-0xcp-1076"), -3*TINY)
        identical(fromHex("-0Xdp-1076"), -3*TINY)
        identical(fromHex("-0xep-1076"), -4*TINY)
        identical(fromHex("-0Xfp-1076"), -4*TINY)
        identical(fromHex("-0X10p-1076"), -4*TINY)

        # and near MIN ...
        identical(fromHex("0x0.ffffffffffffd6p-1022"), MIN-3*TINY)
        identical(fromHex("0x0.ffffffffffffd8p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffdap-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffdcp-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffdep-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffe0p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffe2p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffe4p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffe6p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffe8p-1022"), MIN-2*TINY)
        identical(fromHex("0x0.ffffffffffffeap-1022"), MIN-TINY)
        identical(fromHex("0x0.ffffffffffffecp-1022"), MIN-TINY)
        identical(fromHex("0x0.ffffffffffffeep-1022"), MIN-TINY)
        identical(fromHex("0x0.fffffffffffff0p-1022"), MIN-TINY)
        identical(fromHex("0x0.fffffffffffff2p-1022"), MIN-TINY)
        identical(fromHex("0x0.fffffffffffff4p-1022"), MIN-TINY)
        identical(fromHex("0x0.fffffffffffff6p-1022"), MIN-TINY)
        identical(fromHex("0x0.fffffffffffff8p-1022"), MIN)
        identical(fromHex("0x0.fffffffffffffap-1022"), MIN)
        identical(fromHex("0x0.fffffffffffffcp-1022"), MIN)
        identical(fromHex("0x0.fffffffffffffep-1022"), MIN)
        identical(fromHex("0x1.00000000000000p-1022"), MIN)
        identical(fromHex("0x1.00000000000002p-1022"), MIN)
        identical(fromHex("0x1.00000000000004p-1022"), MIN)
        identical(fromHex("0x1.00000000000006p-1022"), MIN)
        identical(fromHex("0x1.00000000000008p-1022"), MIN)
        identical(fromHex("0x1.0000000000000ap-1022"), MIN+TINY)
        identical(fromHex("0x1.0000000000000cp-1022"), MIN+TINY)
        identical(fromHex("0x1.0000000000000ep-1022"), MIN+TINY)
        identical(fromHex("0x1.00000000000010p-1022"), MIN+TINY)
        identical(fromHex("0x1.00000000000012p-1022"), MIN+TINY)
        identical(fromHex("0x1.00000000000014p-1022"), MIN+TINY)
        identical(fromHex("0x1.00000000000016p-1022"), MIN+TINY)
        identical(fromHex("0x1.00000000000018p-1022"), MIN+2*TINY)

        # and near 1.0.
        identical(fromHex("0x0.fffffffffffff0p0"), 1.0-EPS)
        identical(fromHex("0x0.fffffffffffff1p0"), 1.0-EPS)
        identical(fromHex("0X0.fffffffffffff2p0"), 1.0-EPS)
        identical(fromHex("0x0.fffffffffffff3p0"), 1.0-EPS)
        identical(fromHex("0X0.fffffffffffff4p0"), 1.0-EPS)
        identical(fromHex("0X0.fffffffffffff5p0"), 1.0-EPS/2)
        identical(fromHex("0X0.fffffffffffff6p0"), 1.0-EPS/2)
        identical(fromHex("0x0.fffffffffffff7p0"), 1.0-EPS/2)
        identical(fromHex("0x0.fffffffffffff8p0"), 1.0-EPS/2)
        identical(fromHex("0X0.fffffffffffff9p0"), 1.0-EPS/2)
        identical(fromHex("0X0.fffffffffffffap0"), 1.0-EPS/2)
        identical(fromHex("0x0.fffffffffffffbp0"), 1.0-EPS/2)
        identical(fromHex("0X0.fffffffffffffcp0"), 1.0)
        identical(fromHex("0x0.fffffffffffffdp0"), 1.0)
        identical(fromHex("0X0.fffffffffffffep0"), 1.0)
        identical(fromHex("0x0.ffffffffffffffp0"), 1.0)
        identical(fromHex("0X1.00000000000000p0"), 1.0)
        identical(fromHex("0X1.00000000000001p0"), 1.0)
        identical(fromHex("0x1.00000000000002p0"), 1.0)
        identical(fromHex("0X1.00000000000003p0"), 1.0)
        identical(fromHex("0x1.00000000000004p0"), 1.0)
        identical(fromHex("0X1.00000000000005p0"), 1.0)
        identical(fromHex("0X1.00000000000006p0"), 1.0)
        identical(fromHex("0X1.00000000000007p0"), 1.0)
        identical(fromHex("0x1.00000000000007ffffffffffffffffffffp0"),
                1.0)
        identical(fromHex("0x1.00000000000008p0"), 1.0)
        identical(fromHex("0x1.00000000000008000000000000000001p0"),
                1+EPS)
        identical(fromHex("0X1.00000000000009p0"), 1.0+EPS)
        identical(fromHex("0x1.0000000000000ap0"), 1.0+EPS)
        identical(fromHex("0x1.0000000000000bp0"), 1.0+EPS)
        identical(fromHex("0X1.0000000000000cp0"), 1.0+EPS)
        identical(fromHex("0x1.0000000000000dp0"), 1.0+EPS)
        identical(fromHex("0x1.0000000000000ep0"), 1.0+EPS)
        identical(fromHex("0X1.0000000000000fp0"), 1.0+EPS)
        identical(fromHex("0x1.00000000000010p0"), 1.0+EPS)
        identical(fromHex("0X1.00000000000011p0"), 1.0+EPS)
        identical(fromHex("0x1.00000000000012p0"), 1.0+EPS)
        identical(fromHex("0X1.00000000000013p0"), 1.0+EPS)
        identical(fromHex("0X1.00000000000014p0"), 1.0+EPS)
        identical(fromHex("0x1.00000000000015p0"), 1.0+EPS)
        identical(fromHex("0x1.00000000000016p0"), 1.0+EPS)
        identical(fromHex("0X1.00000000000017p0"), 1.0+EPS)
        identical(fromHex("0x1.00000000000017ffffffffffffffffffffp0"),
                1.0+EPS)
        identical(fromHex("0x1.00000000000018p0"), 1.0+2*EPS)
        identical(fromHex("0X1.00000000000018000000000000000001p0"),
                1.0+2*EPS)
        identical(fromHex("0x1.00000000000019p0"), 1.0+2*EPS)
        identical(fromHex("0X1.0000000000001ap0"), 1.0+2*EPS)
        identical(fromHex("0X1.0000000000001bp0"), 1.0+2*EPS)
        identical(fromHex("0x1.0000000000001cp0"), 1.0+2*EPS)
        identical(fromHex("0x1.0000000000001dp0"), 1.0+2*EPS)
        identical(fromHex("0x1.0000000000001ep0"), 1.0+2*EPS)
        identical(fromHex("0X1.0000000000001fp0"), 1.0+2*EPS)
        identical(fromHex("0x1.00000000000020p0"), 1.0+2*EPS)
    when false: # TODO
      test "bpo 44954":
        identical(fromHex("0x.8p-1074"), 0.0)
        identical(fromHex("0x.80p-1074"), 0.0)
        identical(fromHex("0x.81p-1074"), TINY)
        identical(fromHex("0x8p-1078"), 0.0)
        identical(fromHex("0x8.0p-1078"), 0.0)
        identical(fromHex("0x8.1p-1078"), TINY)
        identical(fromHex("0x80p-1082"), 0.0)
        identical(fromHex("0x81p-1082"), TINY)
        identical(fromHex(".8p-1074"), 0.0)
        identical(fromHex("8p-1078"), 0.0)
        identical(fromHex("-.8p-1074"), -0.0)
        identical(fromHex("+8p-1078"), 0.0)

suite "float.fromhex and hex":
    test "roundtrip":
        def roundtrip(x):
            return fromHex(toHex(x))
        for x in [NAN, INF, MAX, MIN, MIN-TINY, TINY, 0.0]:
            identical(x, roundtrip(x))
            identical(-x, roundtrip(-x))
        for i in range(10000):
          let
            e = rand(-1200 .. 1200)
            m = rand 1.0
            s = [1.0, -1.0][rand(1)]
          try:
            let x = s*ldexp(m, e)
            identical(x, fromHex(toHex(x)))
          except OverflowDefect:
            discard

suite "float":
    test "hex":
      check (-0.1).hex() == "-0x1.999999999999ap-4"
      check 3.14159.hex() == "0x1.921f9f01b866ep+1"
    test "test_nan_signs":
        # The sign of float("nan") should be predictable.
        check copysign(1.0, float("nan")) == 1.0
        check copysign(1.0, float("-nan")) == -1.0
    test "is_integer":
      check not ((1.1).is_integer())
      check ((1.0).is_integer())
      check not (float("nan").is_integer())
      check not (float("inf").is_integer())
    test "as_integer_ratio":
        for (f, ratio) in [
                (0.875, (7, 8)),
                (-0.875, (-7, 8)),
                (0.0, (0, 1)),
                (11.5, (23, 2)),
            ]:
            check f.as_integer_ratio() == ratio

        for _ in range(10000):
            var f = rand 1.0
            f *= pow(10.0, float rand(2 .. 15))
            let (n, d) = f.as_integer_ratio()
            check almostEqual(n/d, f)

        check (0, 1) == float(0.0).as_integer_ratio()
        check (5, 2) == float(2.5).as_integer_ratio()
        check (1, 2) == float(0.5).as_integer_ratio()
        when false and sizeof(system.int) > 4: # cannot pass
            check ((system.int 4728779608739021, system.int 2251799813685248) ==
                            (float(2.1).as_integer_ratio()))
            check ((system.int -4728779608739021, system.int 2251799813685248) ==
                            (float(-2.1).as_integer_ratio()))
        check (-2100, 1) == float(-2100.0).as_integer_ratio()

        expect(OverflowError): discard Inf.as_integer_ratio()
        expect(OverflowError): discard (-Inf).as_integer_ratio()
        expect(ValueError):    discard (NaN).as_integer_ratio()
