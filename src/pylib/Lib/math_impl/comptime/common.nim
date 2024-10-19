import ../inWordUtils/[fromWords, toWords]
import ../constsUtils
import ../polevl

export fromWords, toWords,
  constsUtils,
  polExpd0

const
  ln2_hi* = 6.93147180369123816490e-01 ##  3fe62e42 fee00000
  ln2_lo* = 1.90821492927058770002e-10 ##  3dea39ef 35793c76

template getLowWord*(x: float32): uint16 = cast[uint16](cast[uint32](x))
template getLowWord*(x: float64): uint32 = cast[uint32](cast[uint64](x))


template setHighWord*(x: float; hi) =
  x = fromWords(hi, x.getLowWord)

template GET_FLOAT_WORD*(x: float32): uint32 = cast[uint32](x)
template GET_FLOAT_WORD*(word: var uint32, x: float32) = word = GET_FLOAT_WORD(x)

