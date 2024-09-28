
from std/lenientops as mixOps import nil  ## import no symbols directly

from ../isX import isfinite
from ./niter_types import OpenarrayOrNimIter, toNimIterator
from ./private/dl_ops import DoubleLength, dl_mul, dl_sum

type TripleLength = object
  hi, lo, tiny: float

template tl_zero: TripleLength = TripleLength()

func tl_fma(x, y: float; total: TripleLength): TripleLength =
  ##  Algorithm 5.10 with SumKVert for K=3
  let
    pr: DoubleLength = dl_mul(x, y)
    sm: DoubleLength = dl_sum(total.hi, pr.hi)
    r1: DoubleLength = dl_sum(total.lo, pr.lo)
    r2: DoubleLength = dl_sum(r1.hi, sm.lo)
  TripleLength(hi: sm.hi , lo: r2.hi , tiny: total.tiny + r1.lo + r2.lo)

func tl_to_d(total: TripleLength): float =
  let last = dl_sum(total.lo, total.hi)
  total.tiny + last.lo + last.hi


template bool_Check(x): bool = x is bool

template isIntegerType(T): bool = T is SomeInteger
template isFloatType(T): bool = T is SomeFloat


template PyFloat_AS_DOUBLE(x: SomeFloat): float = float x
template PyLong_AS_DOUBLE(x: SomeInteger or bool): float = float x

template PyNumber_Add(a, b): untyped = mixOps.`+` a, b
template Number_iAdd(a, b): untyped = mixOps.`+=` a, b
template PyNumber_Multiply(a, b): untyped = mixOps.`*` a, b


template n_next[T](p: iterable[T]): T = p()
template n_iterStopped(p: iterable): bool = finished p

func math_sumprod_impl[P, Q](p_it: iterable[P]; q_it: iterable[Q]): float =
  ## [clinic input]
  ##
  ## Return the sum of products of values from two iterables p and q.
  ##
  ## Roughly equivalent to:
  ##
  ##     sum(itertools.starmap(operator.mul, zip(p, q, strict=True)))
  ##
  ## For float and mixed int/float inputs, the intermediate products
  ## and sums are computed with extended precision.
  ## [clinic start generated code]
  ## [clinic end generated code: output=6722dbfe60664554 input=82be54fe26f87e30]
  var
    int_path_enabled = true
  const
    p_type_int = isIntegerType(P)
    q_type_int = isIntegerType(Q)
    mayUse_int_total = p_type_int and q_type_int
  when mayUse_int_total: 
    var int_total_in_use = false
  var
    flt_path_enabled = true
    flt_total_in_use = false

  var int_total = 0
  var flt_total: TripleLength
  var
    p_i: P
    q_i: Q
  var
    p_stopped = false
    q_stopped = false

  template Ret = return  # return result

  while true:
    var finished: bool
    assert(p_it != nil)
    assert(q_it != nil)
    p_i = n_next(p_it)
    p_stopped = n_iterStopped p_it
    q_i = n_next(q_it)
    q_stopped = n_iterStopped q_it
    if p_stopped != q_stopped:
      raise newException(ValueError, "Inputs are not the same length")
    finished = p_stopped and q_stopped
    if int_path_enabled:
      when mayUse_int_total:
        if not finished:
          int_total.inc(p_i * q_i)
          int_total_in_use = true
          continue
      ##  We're finished, or have a non-int
      int_path_enabled = false
      when mayUse_int_total:
        if int_total_in_use:
          Number_iAdd(result, int_total)
          int_total = 0
          ##  An ounce of prevention, ...
          int_total_in_use = false
    if flt_path_enabled:
      block flt_fast_path:
        if not finished:
          var
            flt_p: float
            flt_q: float
          const
            p_type_float = isFloatType(P)
            q_type_float = isFloatType(Q)
          when p_type_float and q_type_float:
            flt_p = PyFloat_AS_DOUBLE(p_i)
            flt_q = PyFloat_AS_DOUBLE(q_i)
          elif p_type_float and (q_type_int or bool_Check(q_i)):
            ##  We care about float/int pairs and int/float pairs because
            ##                        they arise naturally in several use cases such as price
            ##                        times quantity, measurements with integer weights, or
            ##                        data selected by a vector of bools.
            flt_p = PyFloat_AS_DOUBLE(p_i)
            flt_q = PyLong_AsDouble(q_i)
          elif q_type_float and (p_type_int or bool_Check(p_i)):
            flt_q = PyFloat_AS_DOUBLE(q_i)
            flt_p = PyLong_AsDouble(p_i)
          else:
            break flt_fast_path
          let new_flt_total = tl_fma(flt_p, flt_q, flt_total)
          if isfinite(new_flt_total.hi):
            flt_total = new_flt_total
            flt_total_in_use = true
            continue
      ##  We're finished, have a non-float, or got a non-finite value
      flt_path_enabled = false
      if flt_total_in_use:
        Number_iAdd(result, tl_to_d(flt_total))
        flt_total = tl_zero
        flt_total_in_use = false
    when mayUse_int_total: 
      assert(not int_total_in_use)
    assert(not flt_total_in_use)
    if finished:
      Ret
    Number_iAdd(result, PyNumber_Multiply(p_i, q_i))
  Ret

func sumprod*[P, Q](p: OpenarrayOrNimIter[P]; q: OpenarrayOrNimIter[Q]): float =
  math_sumprod_impl(p.toNimIterator[P], q.toNimIterator[Q])
