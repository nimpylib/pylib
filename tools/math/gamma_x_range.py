'''calculate the very x in gamma(x) where gamma(x) haven't
over-underflow

'''

# result:
'''
'''

from math import inf
from struct import pack, calcsize
from enum import Enum
from sys import byteorder
FloatType = Enum('FloatType', 'f32 f64')

def in_bin_with_prefix(x: float, ftype):
    ## returns 0b...'f32|f64
    if ftype==FloatType.f32:
        format_ = 'f'
        size = 32
    else:
        format_ = 'd'
        size = 64
    assert calcsize(format_) * 8 == size
    format_ = '>' + format_

    bs = pack(format_, x)
    res = '0b'
    for i in bs:
        res += '{:b}'.format(i).zfill(8) + '_'
    res = res[:-1]
    #i = int.from_bytes(b, byteorder=byteorder, signed=True)
    #res = '{:b}'.format(i).zfill(size)  # '{:#{n}b}' cannot help
    #if i < 0.0:
    #    assert res[0]=='-'
    #    res = res[1:]
    return res

# from sympy import gamma;tgamma = lambda x: float(gamma(x))
from ctypes import cdll, c_double, c_float
libm = cdll['libm.so.6']
def imp_f(func_name, Args = (c_float,), Res=(c_float)):
    res = libm[func_name]
    res.argtypes = Args
    res.restype =  Res
    return res

tgammaf = imp_f("tgammaf")
nextafterf = imp_f("nextafterf", (c_float, )*2)
tgamma = imp_f("tgamma", (c_double,), c_double)
nextafter = imp_f("nextafter", (c_double, )*2, c_double)

def get_shreshold(neg): return 0.0 if neg else inf

def main():
    def cal_and_print(ftype, tgamma, nextafter, ori_x):
        suffix = ftype.name
        (x, nx) = cal_very_x(tgamma, nextafter, ori_x)

        shreshold = get_shreshold(x<0.0)
        assert tgamma(x) != shreshold
        assert tgamma(nx) == shreshold

        pre = "MIN" if x < 0 else "MAX"
        print( "## "+ pre + "_GAMMA_X" ) # header

        suffix = "'" + suffix

        print('',x, suffix, sep='')
        #print('nextafter: ',nx,suffix, sep='')
        print(in_bin_with_prefix(x, ftype),suffix, sep='')
        print()

    def cal_f32(x): cal_and_print(FloatType.f32, tgammaf, nextafterf, x)
    def cal_f64(x): cal_and_print(FloatType.f64, tgamma, nextafter, x)
    cal_f32( "34.9" )
    cal_f32( "-38.6" )

    cal_f64( "171.6")
    cal_f64( "-177.7")


factor = 10  # this value is not that important, just a value greater than 1
def cal_very_x(tgamma, nextafter, x, step=None):
    assert x != 0.0
    if step is None:
        #assert isinstance(x, (str, Fraction, Decimal))
        assert isinstance(x, str)  # float might lost some accuracy from digit format
        idx = x.rfind('.')
        if idx == -1: pre = 1.0
        else:
            istep = len(x) -1 - x.rfind('.')
            pre = 10.0**(-istep)
        x = float(x)
        if x < 0.0:
            pre = -pre
    x = x
    neg = x < 0.0
    shreshold = get_shreshold(neg)
    direct = -inf if neg else inf
    mini_step = lambda x: nextafter(x, direct) - x
    while abs(pre) > abs(mini_step(x)):
        x += pre
        if tgamma(x) == shreshold:
            x -= pre
            pre /= factor

    # the following is necessary
    # as float isn't incresing by digit
    # but by method specified by IEEE-754
    nx = x
    while tgamma(nx) != shreshold:
        x = nx
        nx = nextafter(x, direct) 

    return x, nx


if __name__ == '__main__':
    main()

