
import std/strformat
import std/options
import std/sets
from std/sugar import collect
from std/sequtils import toSeq

from std/math import floorMod
from ../n_math import pow,
  floor, isfinite, log, ceil, sqrt, exp, cos, acos,
  pi, tau, e,
  log2, fabs, lgamma
const TWOPI = tau

from ../n_bisect import bisect
from ../n_itertools import accumulate


import ./macroutils

import ./types
from ./proc_dispatched import randbelow, random, genrand_uint32

template bind_random_self{.dirty.} =
  template random(): untyped = self.random()

#from ../operator import index
func index*[I: Ordinal](x: I): int = int(x)

using self: PyRandom

template raise_ValueError(msg) = raise newException(ValueError, msg)
template raise_TypeError(msg) = raise newException(ValueError, msg)  ## \
## XXX: we use ValueError to avoid pyerrors dep

func `%`(a, b: float): float = floorMod(a, b)

func `**`(x, y: int): int =
  result = 1
  for _ in 1..y:
    result *= x

func `**`(x, y: float): float = pow(x, y)

type Indexable[I: SomeInteger] = concept self
  index(self) is I

template useOr(use, els): untyped =
  when compiles(use): use
  else: els

template newSeqMayUninit[T](len): seq[T] =
  useOr newSeqUninit[T](len), newSeq[T](len)

template newStringMayUninit(len): string =
  useOr newStringUninit(len), newString(len)

const PyLittleEndian = cpuEndian == littleEndian


const bytePerWord = 4
type U8 = uint8 | char
func fromU32sImpl[S: seq[U8]|string](res: var S; wordarray: openArray[uint32]){.inline.} =
  when declared(copyMem):
    copyMem(res[0].addr, wordarray[0].addr, res.len)
  else:
    when PyLittleEndian:
      template rng: untyped = 0..wordarray.high
      template `[]=`(res; i, o, v): untyped = res[i + (3 - o)] = v
    else:
      template rng: untyped = countdown(wordarray.high, 0)
      template `[]=`(res; i, o, v): untyped = res[i + o] = v
    for i in rng:
      let ii = i * bytePerWord
      #unpack wordarray[i], res[ii+3], res[ii+2], res[ii+1], res[ii]
      let u = wordarray[i]
      type T = typeof(res[0])
      template asgnPart(o) =
        res[ii, o] = cast[T](u shr (8 * o))
      asgnPart 0
      asgnPart 1
      asgnPart 2
      asgnPart 3

func fromU32s(res: var seq[U8]; wordarray: openArray[uint32]) =
  res = newSeqMayUninit[U8] wordarray.len * bytePerWord
  res.fromU32sImpl wordarray

func fromU32s(res: var string; wordarray: openArray[uint32]) =
  res = newStringMayUninit wordarray.len * bytePerWord
  res.fromU32sImpl wordarray

func getrandbits_impl(self; k: int): seq[uint32] =
  ## `_random_Random_getrandbits_impl` but returns seq
  if k <= 32:
    return @[genrand_uint32(self) shr (32 - k)]

  let words = (k - 1) div 32 + 1

  result = newSeqMayUninit[uint32](words * 4)

  var k = k
  template rng: untyped =
    when PyLittleEndian: 0..<words
    else: countdown(words-1, 0)

  for i in rng:
    var r = genrand_uint32(self)
    if k < 32:
      r = r shr (32 - k)
    result[i] = r
    k.dec 32

genGbls:
  method randbytes*(self; n: int): string{.base.} =
    ## `return self.getrandbits(n * 8).to_bytes(n, 'little')`
    ## here we use `_random_Random_getrandbits_impl`
    result.fromU32s self.getrandbits_impl n*8

  method getrandbits*(self; k: int): int{.base.} =
    ## `_random_Random_getrandbits_impl`
    ## 
    ## .. hint::
    ##   raises `ValueError` if `k >= 8*sizeof(int)`
    if k == 0:
      return 0
    type R = int
    const
      MaxSize = sizeof(R)
      MaxBit = 8 * MaxSize  ## XXX: as result is signed, MaxBit shall not be included
    assert k < MaxBit

    var res: seq[uint8]
    res.fromU32s self.getrandbits_impl k
    res.setLen MaxSize
    result = cast[ptr R](res[0].addr)[]
    when PyLittleEndian:
      result = result shr (MaxBit - k)

  func randrange*[I: SomeInteger](self; istart, istop: I; istep: I): I =        # This code is a bit messy to make it fast for the
    # common case while still doing adequate error checking.
    let
      width = istop - istart
    # Fast path.
    if istep == 1:
        if width > 0:
          return istart + self.randbelow(width)
        raise_ValueError(fmt"empty range in randrange({start}, {stop})")

    # Non-unit step argument supplied.
    let n =
      if istep > 0:
        (width + istep - 1) div istep
      elif istep < 0:
        (width + istep + 1) div istep
      else:
        raise_ValueError("zero step for randrange()")
    if n <= 0:
        raise_ValueError(fmt"empty range in randrange({start}, {stop}, {step})")
    return istart + istep * self.randbelow(n)

  func randrange*[T; I: Indexable[T]](self; start, stop, step: I): T  =
    self.randrange(index(start), index(stop), index(step))


  func choices*[T](self; population: openArray[T];
      weights = none(openArray[T]);
      cum_weights = none(openArray[T]);
      k=1): seq[T] =
    bind_random_self
    let n = len(population)
    let cum_weights =
      if cum_weights.isNone:
        if weights.isNone:
            let n = float(n)    # convert to float for a small speed improvement
            return collect:
              for _ in 1..k:
                population[floor(random() * n)]
        toSeq(accumulate(weights.unsafeGet))
      elif not weights.isNone:
        raise_TypeError("Cannot specify both weights and cumulative weights")
      else:
        cum_weights.unsafeGet
    
    if len(cum_weights) != n:
        raise_ValueError("The number of weights does not match the population")
    let total = cum_weights[^1].float   # convert to float
    if total <= 0.0:
        raise_ValueError("Total of weights must be greater than zero")
    if not isfinite(total):
        raise_ValueError("Total of weights must be finite")
    let hi = n - 1
    return collect:
      for _ in 1..k:
        population[bisect(cum_weights, random() * total, 0, hi)]


template shuffleImpl*(self: PyRandom; x) =
  ## inner. unstable.
  for i in countdown(len(x)-1, 1):
    # pick an element in x[:i+1] with which to exchange x[i]
    let j = self.randbelow(i + 1)
    (x[i], x[j]) = (x[j], x[i])


genGbls:
  func shuffle*[T](self; x: var seq[T]) =
    self.shuffleImpl x

  func sample*[T](self; population: openArray[T], k: int): seq[T] =
    # Sampling without replacement entails tracking either potential
    # selections (the pool) in a list or previous selections in a set.

    # When the number of selections is small compared to the
    # population, then tracking selections is efficient, requiring
    # only a small set and an occasional reselection.  For
    # a larger number of selections, the pool tracking method is
    # preferred since the list takes less space than the
    # set and it doesn't suffer from frequent reselections.

    # The number of calls to _randbelow() is kept at or near k, the
    # theoretical minimum.  This is important because running time
    # is dominated by _randbelow() and because it extracts the
    # least entropy from the underlying random number generators.

    # Memory requirements are kept to the smaller of a k-length
    # set or an n-length list.

    # There are other sampling algorithms that do not require
    # auxiliary memory, but they were rejected because they made
    # too many calls to _randbelow(), making them slower and
    # causing them to eat more entropy than necessary.

    
    #if not isinstance(population, _Sequence):
    #    raise_TypeError("Population must be a sequence.  "
    #                    "For dicts or sets, use sorted(d).")
    let n = len(population)

    template randbelow(x): untyped = self.randbelow(x)
    if not (0 <= k and k <= n):
        raise_ValueError("Sample larger than population or is negative")
    result =
      when compiles(newSeqUninit[T](k)): newSeqUninit[T](k)
      else: newSeq[T](k)
    var setsize = 21        # size of a small set minus size of an empty list
    if k > 5:
      setsize += 4 ** ceil(log(k * 3, 4))  # table size for big sets
    if n <= setsize:
        # An n-length list is smaller than a k-length set.
        # Invariant:  non-selected at pool[0 : n-i]
        var pool = toSeq(population)
        for i in 0..<k:
            let j = randbelow(n - i)
            result[i] = pool[j]
            pool[j] = pool[n - i - 1]  # move non-selected item into vacancy
    else:
        var selected = initHashSet[T]()
        template selected_add(x) = selected.add(x)
        for i in 0..<k:
            var j = randbelow(n)
            while j in selected:
                j = randbelow(n)
            selected_add(j)
            result[i] = population[j]
    return result

  func sample*[T](self; population: openArray[T], k: int, counts: openArray[T]): seq[T] =
    let n = len(population)
    let cum_counts = toSeq(accumulate(counts))
    if len(cum_counts) != n:
        raise_ValueError("The number of counts does not match the population")
    let total = cum_counts.pop()
    when not (total is int):
      #raise TypeError
      {.error: "Counts must be integers".}
    if total <= 0:
      raise_ValueError("Total of counts must be greater than zero")
    let selections = self.sample(toSeq(0..<total), k=k)
    return collect:
      for s in selections:
        population[bisect(cum_counts, s)]


template triangularImpl(declC) =
  let u = self.random()
  declC
  var (low, high) = (low, high)
  if u > c:
      u = 1.0 - u
      c = 1.0 - c
      (low, high) = (high, low)
  return low + (high - low) * sqrt(u * c)

genGbls:
  func triangular*[F: SomeFloat](self; low: F = 0.0, high: F = 1.0): F =
    triangularImpl:
      const c = 0.5
  func triangular*[F: SomeFloat](self; low: F = 0.0, high: F = 1.0; mode: F): F =
    triangularImpl:
      let d = high - low
      if d == 0:
        return low
      let c = (mode - low) / d


  func normalvariate*(self; mu=0.0, sigma=1.0): float =
    # Uses Kinderman and Monahan method. Reference: Kinderman,
    # A.J. and Monahan, J.F., "Computer generation of random
    # variables using the ratio of uniform deviates", ACM Trans
    # Math Software, 3, (1977), pp257-260.

    const NV_MAGICCONST = 4 * exp(-0.5) / sqrt(2.0)
    var u1, u2, z, zz: float
    while true:
      u1 = self.random()
      u2 = 1.0 - self.random()
      z = NV_MAGICCONST * (u1 - 0.5) / u2
      zz = z * z / 4.0
      if zz <= -log(u2):
        break
    return mu + z * sigma

  func lognormalvariate*(self; mu, sigma: float): float =
    exp(self.normalvariate(mu, sigma))
  
  func expovariate*(self; lambd=1.0): float =
    -log(1.0 - self.random()) / lambd
  
  func vonmisesvariate*(self; mu, kappa: float): float =
    bind_random_self
    if kappa <= 1e-6:
      return TWOPI * random()

    let
      s = 0.5 / kappa
      r = s + sqrt(1.0 + s * s)

    var z: float
    while true:
      let u1 = random()
      z = cos(pi * u1)

      let
        d = z / (r + z)
        u2 = random()
      if u2 < 1.0 - d * d or u2 <= (1.0 - d) * exp(d):
          break

    let
      q = 1.0 / r
      f = (q + z) / (1.0 + q * z)
      u3 = random()
    if u3 > 0.5:
      (mu + acos(f)) % TWOPI
    else:
      (mu - acos(f)) % TWOPI

  func gammavariate*(self; alpha, beta: float): float =
    if alpha <= 0.0 or beta <= 0.0:
        raise_ValueError("gammavariate: alpha and beta must be > 0.0")

    bind_random_self
    if alpha > 1.0:

      # Uses R.C.H. Cheng, "The generation of Gamma
      # variables with non-integral shape parameters",
      # Applied Statistics, (1977), 26, No. 1, p71-74

      const
        LOG4 = log(4.0)
        SG_MAGICCONST = 1.0 + log(4.5)
      let
        ainv = sqrt(2.0 * alpha - 1.0)
        bbb = alpha - LOG4
        ccc = alpha + ainv

      var u1: float
      while true:
        u1 = random()
        if not (1e-7 < u1 and u1 < 0.9999999):
          continue
        let
          u2 = 1.0 - random()
          v = log(u1 / (1.0 - u1)) / ainv
          x = alpha * exp(v)
          z = u1 * u1 * u2
          r = bbb + ccc * v - x
        if r + SG_MAGICCONST - 4.5 * z >= 0.0 or r >= log(z):
          return x * beta

    elif alpha == 1.0:
      # expovariate(1/beta)
      return -log(1.0 - random()) * beta

    else:
      # alpha is between 0 and 1 (exclusive)
      # Uses ALGORITHM GS of Statistical Computing - Kennedy & Gentle
      var x: float
      while true:
        let
          u = random()
          b = (e + alpha) / e
          p = b * u
          u1 = random()
        x =
          if p <= 1.0:
            p ** (1.0 / alpha)
          else:
            -log((b - p) / alpha)
        if p > 1.0:
            if u1 <= x ** (alpha - 1.0):
              break
        elif u1 <= exp(-x):
            break
      return x * beta

  func betavariate*(self; alpha, beta: float): float =
    ##[Beta distribution.

    Conditions on the parameters are alpha > 0 and beta > 0.
    Returned values range between 0 and 1.

    The mean (expected value) and variance of the random variable are:

      ```python
        E[X] = alpha / (alpha + beta)
        Var[X] = alpha * beta / ((alpha + beta)**2 * (alpha + beta + 1))
      ```
    ]##
    ## See
    ## http://mail.python.org/pipermail/python-bugs-list/2001-January/003752.html
    ## for Ivan Frohne's insightful analysis of why the original implementation:
    ##
    ##    def betavariate(self, alpha, beta):
    ##        # Discrete Event Simulation in C, pp 87-88.
    ##
    ##        y = self.expovariate(alpha)
    ##        z = self.expovariate(1.0/beta)
    ##        return z/(y+z)
    ##
    ## was dead wrong, and how it probably got that way.

    # This version due to Janne Sinkkonen, and matches all the std
    # texts (e.g., Knuth Vol 2 Ed 3 pg 134 "the beta distribution").
    let y = self.gammavariate(alpha, 1.0)
    if y != 0:
      return y / (y + self.gammavariate(beta, 1.0))
    return 0.0

  func paretovariate*(self; alpha: float): float =
    ## Pareto distribution.  alpha is the shape parameter.
    # Jain, pg. 495

    let u = 1.0 - self.random()
    return u ** (-1.0 / alpha)

  func weibullvariate*(self; alpha, beta: float): float =
      ##[ Weibull distribution.

      alpha is the scale parameter and beta is the shape parameter.

      ]##
      # Jain, pg. 499; bug fix courtesy Bill Arms

      let u = 1.0 - self.random()
      return alpha * (-log(u)) ** (1.0 / beta)


  # -------------------- discrete  distributions  ---------------------

  func binomialvariate*(self; n=1.0, p=0.5): float =
    ##[ Binomial random variable.

    Gives the number of successes for *n* independent trials
    with the probability of success in each trial being *p*:

        sum(random() < p for i in range(n))

    Returns an integer in the range:   0 <= X <= n

    The mean (expected value) and variance of the random variable are:

      ```
        E[X] = n * p
        Var[x] = n * p * (1 - p)
      ```

    ]###
    # Error check inputs and handle edge cases
    if n < 0:
      raise_ValueError("n must be non-negative")
    if p <= 0.0 or p >= 1.0:
      if p == 0.0:
          return 0
      if p == 1.0:
          return n
      raise_ValueError("p must be in the range 0.0 <= p <= 1.0")

    bind_random_self

    # Fast path for a common case
    if n == 1:
      return float(index(random() < p))

    # Exploit symmetry to establish:  p <= 0.5
    if p > 0.5:
      return n - self.binomialvariate(n, 1.0 - p)

    if n * p < 10.0:
      # BG: Geometric method by Devroye with running time of O(np).
      # https://dl.acm.org/doi/pdf/10.1145/42372.42381
      var
        x = 0
        y = 0
      let c = log2(1.0 - p)
      if c == 0:
        return float(x)
      while true:
        y += floor(log2(random()) / c) + 1
        if float(y) > n:
          return float(x)
        x += 1

    # BTRS: Transformed rejection with squeeze method by Wolfgang Hörmann
    # https://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.47.8407&rep=rep1&type=pdf
    assert n*p >= 10.0 and p <= 0.5
    var
      setup_complete = false


      spq = sqrt(n * p * (1.0 - p))  # Standard deviation of the distribution
      b = 1.15 + 2.53 * spq
      a = -0.0873 + 0.0248 * b + 0.01 * p
      c = n * p + 0.5
      vr = 0.92 - 4.2 / b


    var
      m,
        alpha, lpq,
        h: float
    while true:
      var u = random()
      u -= 0.5
      let us = 0.5 - fabs(u)
      let k = float(floor((2.0 * a / us + b) * u + c))
      if k < 0 or k > n:
        continue

      # The early-out "squeeze" test substantially reduces
      # the number of acceptance condition evaluations.
      var v = random()
      if us >= 0.07 and v <= vr:
        return k

      # Acceptance-rejection test.
      # Note, the original paper erroneously omits the call to log(v)
      # when comparing to the log of the rescaled binomial distribution.
      if not setup_complete:
        alpha = (2.83 + 5.1 / b) * spq
        lpq = log(p / (1.0 - p))
        m = float(floor((n + 1) * p))         # Mode of the distribution
        h = lgamma(m + 1) + lgamma(n - m + 1)
        setup_complete = true           # Only needs to be done once
      v *= alpha / (a / (us * us) + b)
      if log(v) <= h - lgamma(k + 1) - lgamma(n - k + 1) + (k - m) * lpq:
        return k

