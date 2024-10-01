

from ../isX import isfinite
from ./niter_types import OpenarrayOrNimIter, toNimIterator, ClosureIter
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

#template PyNumber_Add[F: SomeNumber](a, b: F): F = system.`+` a, b
#template PyNumber_Add(a, b): untyped = mixOps.`+` a, b

template number_iAdd[F: SomeNumber](a, b: F) = system.`+=` a, b
template number_iAdd(a: float, b: int) = a += float b

template mixin_Multiply_Add[P, Q](res: var float, a: P, b: Q) =
  mixin `+=`, `*`
  `+=`(res, `*`(a, b))

template n_next[T](p: ClosureIter[T]): T = p()
template n_iterStopped(p: ClosureIter): bool = finished p

template sumprodImplWithDoEach[P, Q](p_i: P, q_i: Q; body) =
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
  const
    p_type_int = isIntegerType(P)
    q_type_int = isIntegerType(Q)
    use_int_path = p_type_int and q_type_int
  when use_int_path: 
    # we're in static-typed implementation
    #var int_path_enabled = true
    #var int_total_in_use = false
    var int_total = 0
  else: 
    const
      p_type_float = isFloatType(P)
      q_type_float = isFloatType(Q)
    # we're in static-typed implementation
    #var flt_path_enabled = true
    var flt_total_in_use = false
    var flt_total: TripleLength

  template Ret{.inject.} = return  # return result
  template doEach(finished{.inject.}: bool; Continue){.inject.} =
    when use_int_path:
      if not finished:
        int_total.inc(p_i * q_i)
        Continue
      # We're finished
      result.number_iAdd int_total
      int_total = 0
      Ret
    else:
      template push_flt_total =
        # We're finished, or got a non-finite value
        if flt_total_in_use:
          result.number_iAdd tl_to_d(flt_total)
          flt_total = tl_zero
          flt_total_in_use = false

      if not finished:
        template gen_flt_fast_path(do_p, do_q) =
          let
            flt_p = do_p p_i
            flt_q = do_p q_i
            new_flt_total = tl_fma(flt_p, flt_q, flt_total)
          if isfinite(new_flt_total.hi):
            flt_total = new_flt_total
            flt_total_in_use = true
            Continue
          push_flt_total
        when p_type_float and q_type_float:
          gen_flt_fast_path PyFloat_AS_DOUBLE, PyFloat_AS_DOUBLE
        elif p_type_float and (q_type_int or bool_Check(q_i)):
          ##  We care about float/int pairs and int/float pairs because
          ##  they arise naturally in several use cases such as price
          ##  times quantity, measurements with integer weights, or
          ##  data selected by a vector of bools.
          gen_flt_fast_path PyFloat_AS_DOUBLE, PyLong_AsDouble
        elif (p_type_int or bool_Check(p_i)) and q_type_float:
          gen_flt_fast_path PyLong_AsDouble, PyFloat_AS_DOUBLE

        ## not in `flt_fast_path`
        # We have a non-float value or non-finite
        # XXX: here no need for nimpylib to check `flt_total`
        #  as this implementation is static-typed
        assert not flt_total_in_use
        result.mixin_Multiply_Add(p_i, q_i)
      else:
        push_flt_total
        Ret

  body

template raiseNotSameLen =
  raise newException(ValueError, "Inputs are not the same length")

template Continue = continue

func sumprod*[P, Q](p_it: ClosureIter[P]; q_it: ClosureIter[Q]): float =
  var
    p_i: P
    q_i: Q
  var
    finished: bool
    p_stopped = false
    q_stopped = false
  sumprodImplWithDoEach(p_i, q_i):
    while true:
      p_i = n_next(p_it)
      p_stopped = n_iterStopped p_it
      q_i = n_next(q_it)
      q_stopped = n_iterStopped q_it
      if p_stopped != q_stopped:
        raiseNotSameLen
      finished = p_stopped and q_stopped
      doEach finished, Continue

func sumprod*[P, Q](p: openarray[P]; q: openarray[Q]): float =
  ## a faster version for openarray than that for ClosureIter
  var
    p_i: P
    q_i: Q
  sumprodImplWithDoEach(p_i, q_i):
    let le = p.len
    if le != q.len:
      raiseNotSameLen
    for i in 0..<le:
      p_i = p[i]
      q_i = q[i]
      doEach finished=false, Continue
    doEach finished=true, Ret
