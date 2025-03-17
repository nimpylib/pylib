

import ./time_t_decl
export time_t_decl
type
  long* = clong

type
  Timestamp* = int|float
  PyTime* = int64  ## `PyTime_t`, time in ns

# pycore_time.h
# L91
type
  PyTime_round_t* = enum  ## _PyTime_round_t
    prFLoor
    prCeiling
    prHalfEven
    prRoundUp

const prTimeout* = prRoundUp
