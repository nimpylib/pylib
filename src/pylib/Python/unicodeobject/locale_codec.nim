
import ./wchar_utils
import ../../pyerrors/unicode_err
import ../internal/pycore_fileutils
import ../fileutils

type
  PyStrData = cstring

# unicodeobject.c

# L3980
proc unicode_decode_locale(str: PyStrData, len: int,
    errors: Py_error_handler, current_locale: bool): string =
  if str[len] != '\0' or len != str.len:
    raise newException(ValueError, "embedded null byte")
  var
    wstr: ptr wchar_t
    wlen: csize_t
    reason: cstring
  let res = Py_DecodeLocaleEx(str, wstr, wlen.addr, reason,
                              current_locale, errors)

  if res != 0:
    if res == -2:
      raise newUnicodeDecodeError(
        "locale", str[wlen], wlen.int, int wlen+1, $reason
      )
    elif res == -3:
      raise newException(ValueError, "unsupported error handler")
    else:
      raise newException(OutOfMemDefect, "unicode_decode_locale")
    
  result = wstr $ wlen
  wstr.deallocWcArr()

# L4029
proc PyUnicode_DecodeLocale*(str: PyStrData, errors: string): string =
  let size = str.len
  let error_handler = Py_GetErrorHandler(errors)
  return unicode_decode_locale(str, size, error_handler, true)

