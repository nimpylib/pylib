# Contributing to NimPylib


## Lib/

If in one library: `LIB`, one API returns str
or a variable is of str, consider firstly port a `n_LIB`
that is only in pure Nim (NimPylib-independent) if possible.

For example, `n_time` for `time`, in which `string` shall be used.
Then let `LIB` import `n_LIB` and wrap around `string` to only return `PyStr`.

So does for `seq` <-> `PyList`.

In such a way, `n_LIB` is for Nim and `LIB` is for NimPylib.


