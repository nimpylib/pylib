
# translated from CPython-3.13-alpha/Python/fileutils.c

import ./force_ascii_utils
import ./unicodeobject/utf8_codec

const
  MBSTOWCS_DEST_MAY_NULL = defined(posix) or defined(windows)
  HAVE_BROKEN_MBSTOWCS = not MBSTOWCS_DEST_MAY_NULL

import ./wchar_t as wchar_t_utils
export wchar_t_utils
import ./internal/pycore_fileutils

when not defined(windows):
  import std/posix  # nl_langinfo, CODESET

# L61
proc get_surrogateescape(errors: Py_error_handler, surrogateescape: var bool): int =
  case errors
  of Py_ERROR_STRICT:
    surrogateescape = false
  of Py_ERROR_SURROGATEESCAPE:
    surrogateescape = true
  else:
    return -1

# L176
const USE_FORCE_ASCII = not Py_FORCE_UTF8_FS_ENCODING and not defined(windows)



template `-`(a, b: ptr|cstring): csize_t =
  cast[int](a).csize_t - cast[int](b).csize_t

proc decode_current_locale(arg: cstring, wstr: var ptr wchar_t, wlen: ptr csize_t,
    reason: var cstring, errors: Py_error_handler): int =
  var
    res: ptr wchar_t        
    argsize, count: csize_t
  var
    inp: cstring
    outp: ptr wchar_t
    mbs: mbstate_t
  var surrogateescape: bool
  if get_surrogateescape(errors, surrogateescape) < 0:
    return -3
  argsize =
    when HAVE_BROKEN_MBSTOWCS: arg.len
    else: Py_mbstowcs(nil, arg, 0)
  if argsize != DECODE_ERROR:
    if argsize > MaxWStrLen - 1:
      return -1
    res = allocWcharArr(argsize+1)
    if res == nil:
      return -1
    count = Py_mbstowcs(res, arg, argsize + 1)
    if count != DECODE_ERROR:
      wstr = res
      if wlen != nil:
        wlen[] = count
      return 0
    res.deallocWcArr()

  # Conversion failed. Fall back to escaping with surrogateescape.

  # Try conversion with mbrtwoc (C99), and escape non-decodable bytes.

  #[Overallocate; as multi-byte characters are in the argument, the
    actual output could use less memory.]#
  argsize = typeof(argsize) arg.len + 1
  if argsize > MaxWStrLen:
    return -1
  res = allocWcharArr argsize
  if res == nil:
    return -1
  inp = arg
  outp = res

  # `var mbs: mbstate_t` has set mbs `0` alreadly.

  template inc[I: SomeInteger](s: cstring, i: I = 1) =
    s = cast[cstring](I(cast[int](s)) + i)
  block decode_no_error:
    while argsize != 0:
      let converted = Py_mbrtowc(outp, inp, argsize, mbs)
      if converted == 0:
        break
      
      if converted == INCOMPLETE_CHARACTER:
        #[Incomplete character. This should never happen,
          since we provide everything that we have -
          unless there is a bug in the C library, or I
          misunderstood how mbrtowc works. ]#
        break decode_no_error
      
      if converted == DECODE_ERROR:
        if not surrogateescape:
          break decode_no_error
        
        #[Decoding error. Escape as UTF-8b, and start over in the initial
          shift state.]#
        
        outp[0] = wchar_t(0xdc00) + wchar_t(inp[0])
        inp.inc
        outp.inc

        argsize.dec

        mbs = mbstate_t()
        continue
      
      # _Py_mbrtowc() reject lone surrogate characters
      assert not Py_UNICODE_IS_SURROGATE outp[]

      # successfully converted some bytes
      inp.inc converted
      argsize -= converted
      outp.inc
    if wlen != nil:
      wlen[] = outp - res
    wstr = res
    return 0
  
  # deode_error:
  res.deallocWcArr()
  if wlen != nil:
    wlen[] = inp - arg
  reason = "decoding error"
  return -2


when not HAVE_MBRTOWC or USE_FORCE_ASCII:
  # L401 decode_ascii
  proc decode_ascii(arg: cstring, wstr: var ptr wchar_t, wlen: ptr csize_t,
      reason: var cstring, errors: Py_error_handler): int =
    
    type uchar = byte  ## unsigned char
    var
      res: ptr wchar_t        
      argsize = arg.len + 1
      inp: ptr uchar
      outp: ptr wchar_t
    var surrogateescape: bool
    if get_surrogateescape(errors, surrogateescape) < 0:
      return -3

    if argsize > MaxWStrLen:
      return -1
    res = allocWcharArr argsize
    if res == nil:
      return -1
    outp = res
    inp = cast[ptr uchar](arg)
    template inc(p: ptr uchar, i=0) =
      p = cast[ptr uchar](cast[int](p) + i)
    while inp[] != uchar(0):
      let ch = inp[]
      if ch < wchar_t(128):
        outp[] = ch
        outp.inc
      else:
        if not surrogateescape:
          res.deallocWcArr()
          if wlen != nil:
            wlen[] = inp - cast[typeof(inp)](arg)
          reason = "decoding error"
          return -2
        outp[] = typeof(outp[])(0xdc00) +
                  typeof(outp[])(ch)
        outp.inc

      inp.inc

    outp[] = typeof(outp[])(0)


# L602 _Py_DecodeLocaleEx
proc Py_DecodeLocaleEx*(arg: cstring, wstr: var ptr wchar_t, wlen: ptr csize_t, reason: var cstring, 
    current_locale: bool, errors: Py_error_handler): int =
  ##[Decode a byte string from the locale encoding.

   Use the strict error handler if 'surrogateescape' is zero.  Use the
   surrogateescape error handler if 'surrogateescape' is non-zero: undecodable
   bytes are decoded as characters in range U+DC80..U+DCFF. If a byte sequence
   can be decoded as a surrogate character, escape the bytes using the
   surrogateescape error handler instead of decoding them.

   On success, return 0 and write the newly allocated wide character string into
   `wstr` (use PyMem_RawFree() to free the memory). If wlen is not NULL, write
   the number of wide characters excluding the null character into `wlen`.

   On memory allocation failure, return -1.

   On decoding error, return -2. Write the start of
   invalid byte sequence in the input string into `wlen`. If reason is not NULL,
   write the decoding error message into `reason`.

   Return -3 if the error handler 'errors' is not supported.

   Use the Py_EncodeLocaleEx() function to encode the character string back to
   a byte string.]##
  template retUtf8 =
    return Py_DecodeUTF8Ex(arg, arg.len.csize_t, wstr, wlen, reason, errors)
  template retCurLocale =
    return decode_current_locale(arg, wstr, wlen, reason, errors)
  if current_locale:
    when Py_FORCE_UTF8_LOCALE:
      retUtf8 
    else:
      retCurLocale
    
  when Py_FORCE_UTF8_FS_ENCODING:
    retUtf8
  else:
    var `PyRuntime.preconfig.utf8_mode` = -1 # _PyRuntime.preconfig.utf8_mode
    when defined(windows):
      var `PyRuntime.preconfig.legacy_windows_fs_encoding` = 0 # _PyRuntime.preconfig.legacy_windows_fs_encoding
    var use_utf8 = (`PyRuntime.preconfig.utf8_mode` >= 1)
    when defined(windows):
      use_utf8 = use_utf8 or `PyRuntime.preconfig.legacy_windows_fs_encoding` == 0

    if bool use_utf8:
      retUtf8

    when USE_FORCE_ASCII:
      if force_ascii == -1:
        force_ascii = int check_force_ascii()
      
      if bool force_ascii:
        # force ASCII encoding to workaround mbstowcs() issue
        return decode_ascii(arg, wstr, wlen, reason, errors)

    retCurLocale

const Utf8* = "utf-8"

# L903 _Py_GetLocaleEncoding
proc Py_GetLocaleEncoding*(): string =
  ##  Get the current locale encoding name:
  ##
  ##  - Return "utf-8" if Py_FORCE_UTF8_LOCALE is defined (ex: on Android)
  ##  - Return "utf-8" if the UTF-8 Mode is enabled
  ##  - On Windows, return the ANSI code page (ex: "cp1250")
  ##  - Return "utf-8" if nl_langinfo(CODESET) returns an empty string.
  ##  - Otherwise, return nl_langinfo(CODESET).
  ##
  ##
  ##  See also config_get_locale_encoding()
  when Py_FORCE_UTF8_LOCALE:
    ##  On Android langinfo.h and CODESET are missing,
    ##  and UTF-8 is always used in mbstowcs() and wcstombs().
    return Utf8
  else:
    when defined(windows):
      proc getACP(): cuint{.importc, header: "<winnls.h>".}
      var ansi_codepage: cuint = getACP()
      let encoding = "cp" & $ansi_codepage
      return encoding
    else:
      let encoding: cstring = nl_langinfo(CODESET)
      if encoding == nil or encoding[0] == '\x00':
        ##  Use UTF-8 if nl_langinfo() returns an empty string. It can happen on
        ##  macOS if the LC_CTYPE locale is not supported.
        return Utf8
      # Here CPython does followings, but we just do not use widestr,
      #  so no need to convert
      # decode_current_locale(encoding, addr(wstr), nil, nil,
      #    _Py_ERROR_SURROGATEESCAPE)
      return $encoding

