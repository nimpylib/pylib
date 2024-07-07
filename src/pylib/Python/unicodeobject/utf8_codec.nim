
# unicodeobject.C

import ../wchar_t as wchar_t_lib
import ../internal/pycore_fileutils

const MaxWStrLen* = high(int) div sizeof(wchar_t)

# L5268 _Py_DecodeUTF8Ex
proc Py_DecodeUTF8Ex*(arg: cstring, size: csize_t, wstr: var ptr wchar_t, wlen: ptr csize_t, reason: var cstring,
    errors: Py_error_handler): int =
  ##[
  UTF-8 decoder: use surrogateescape error handler if 'surrogateescape' is
   non-zero, use strict error handler otherwise.

   On success, write a pointer to a newly allocated wide character string into
   *wstr (use PyMem_RawFree() to free the memory) and write the output length
   (in number of wchar_t units) into *wlen (if wlen is set).

   On memory allocation failure, return -1.

   On decoding error (if surrogateescape is zero), return -2. If wlen is
   non-NULL, write the start of the illegal byte sequence into *wlen. If reason
   is not NULL, write the decoding error message into *reason.]##
  
  var surrogateescape, surrogatepass: bool

  case errors
  of Py_ERROR_STRICT: discard
  of Py_ERROR_SURROGATEESCAPE:
    surrogateescape = true
  of Py_ERROR_SURROGATEPASS:
    surrogatepass = true
  else:
    return -3
  
  if MaxWStrLen > size:
    return -1
  
  # Unpack UTF-8 encoded data
  doAssert false, "Not Impl"

  