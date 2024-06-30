
# translated from CPython-3.13-alpha/Python/fileutils.c

import ./wchar_t as wchar_t_utils
export wchar_t_utils

when not defined(windows):
  import std/posix  # nl_langinfo, CODESET

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
  when defined(Py_FORCE_UTF8_LOCALE):
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

