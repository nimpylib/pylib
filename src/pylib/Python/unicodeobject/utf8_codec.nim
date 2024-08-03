
# unicodeobject.C

import ./ptr_op, ./char_decl
import ../wchar_t as wchar_t_lib except inc
import ../internal/pycore_fileutils
import ./codecs

const
  MaxWStrLen* = high(int) div sizeof(wchar_t)

# unicodeobject.h

const WC4 = sizeof(wchar_t) == 4
when not WC4:
  # L35
  proc Py_UNICODE_HIGH_SURROGATE(ch: Py_UCS4): Py_UCS4 =
    ## High surrogate = top 10 bits added to 0xD800.
    ## The character must be in the range [U+10000; U+10ffff].
    assert(0x10000 <= ch.ord and ch.ord <= 0x10ffff)
    result = Py_UCS4(0xD800 - (0x10000 shr 10) + (ch.ord shr 10))

  proc Py_UNICODE_LOW_SURROGATE(ch: Py_UCS4): Py_UCS4 =
    ## Low surrogate = bottom 10 bits added to 0xDC00.
    ## The character must be in the range [U+10000; U+10ffff].
    assert(0x10000 <= ch.ord and ch.ord <= 0x10ffff)
    result = Py_UCS4(0xDC00 + (ch.ord and 0x3FF))

# L5268 _Py_DecodeUTF8Ex
proc Py_DecodeUTF8Ex*(orig_s: cstring, size: csize_t,
    wstr: var ptr wchar_t, wlen: ptr csize_t, reason: var cstring,
    errors: Py_error_handler): int =
  ##[
  UTF-8 decoder: use surrogateescape error handler if 'surrogateescape' is
   non-zero, use strict error handler otherwise.

   On success, write a pointer to a newly allocated wide character string into
   `wstr` (use PyMem_RawFree() to free the memory) and write the output length
   (in number of wchar_t units) into `wlen` (if wlen is set).

   On memory allocation failure, return -1.

   On decoding error (if surrogateescape is zero), return -2. If wlen is
   non-NULL, write the start of the illegal byte sequence into `wlen`. If reason
   is not NULL, write the decoding error message into `reason`.]##
  
  var surrogateescape, surrogatepass: bool

  case errors
  of Py_ERROR_STRICT: discard
  of Py_ERROR_SURROGATEESCAPE:
    surrogateescape = true
  of Py_ERROR_SURROGATEPASS:
    surrogatepass = true
  else:
    return -3

  # Note: size will always be longer than the resulting Unicode character count
  if MaxWStrLen > size:
    return -1
  

  # XXX: maybe consider using std/encoding
  # but may be a little inefficient:
  #  - convert between string and cstring/ptr wchar_t
  #  - handle error via catching exception

  var unicode = allocWcharArr size+1

  if unicode == nil:
    return -1
  
  # Unpack UTF-8 encoded data
  var s = cast[ptr char](orig_s)
  let e = s + size
  var outpos = 0
  type WlenType = typeof(wlen[])
  while s <% e:
    var ch: Py_UCS4
    when WC4:
      ch = utf8_decode[Py_UCS4](s, e, unicode, outpos)
    else:
      ch = utf8_decode[Py_UCS2](s, e, (ptr Py_UCS2)unicode, outpos)

    if ch.ord > 0xFF:
      when WC4:
        doAssert false, "unreachable"
      else:
        assert ch.ord > 0xFFFF and ch.int <= MAX_UNICODE_val
        # write a surrogate pair
        unicode[outpos] = wchar_t Py_UNICODE_HIGH_SURROGATE(ch)
        outpos.inc
        unicode[outpos] = wchar_t Py_UNICODE_LOW_SURROGATE(ch)
        outpos.inc
    else:
      if not bool(ch) and s == e:
        break
      if surrogateescape:
        unicode[outpos] = wchar_t(0xDC00 + byte s[])
        s.inc
        outpos.inc
      else:
        template `and`(c: char, i: int): int = int(c) and i
        if (surrogatepass and
          (e - s) >= 3 and
          (s[0] and 0xf0) == 0xe0 and
          (s[1] and 0xc0) == 0x80 and
          (s[2] and 0xc0) == 0x80):
          ch = typeof(ch) ((s[0] and 0x0f) shl 12) + ((s[1] and 0x3f) shl 6) + (s[2] and 0x3f)
          s.inc 3
          unicode[outpos] = cast[wchar_t](ch)
          outpos.inc
        else:
          unicode.deallocWcArr()
          reason = case ch.ord
            of 0: cstring"unexpected end of data"
            of 1: cstring"invalid start byte"
            else: cstring"invalid continuation byte"

          if wlen != nil:
            wlen[] = cast[WlenType](s) - cast[WlenType](orig_s)
          
          return -2
 
  unicode[outpos] = wchar_t 0
  if wlen != nil:
    wlen[] = WlenType outpos
  wstr = unicode
  return 0      
