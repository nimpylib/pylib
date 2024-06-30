
when defined(windows):
  type wchar_t*{.importc, header: "<wchar.h>".} = uint16
else:
  type wchar_t*{.importc, header: "<wchar.h>".} = uint32

# unicodeobject.c
# #define Py_UNICODE_IS_SURROGATE(ch) (0xD800 <= (ch) && (ch) <= 0xDFFF)
template Py_UNICODE_IS_SURROGATE*(ch: wchar_t): bool =
  (0xD800.wchar_t <= (ch) and (ch) <= 0xDFFF.wchar_t)
const MAX_UNICODE_val = 0x10ffff

# ref
# https://github.com/python/cpython/commit/d3cc6890#diff-90d08e583c4c9c6f391b2ae90f819f600a6326928ea9512c9e0c6d98e9f29ac2R15126
const HAVE_NON_UNICODE_WCHAR_T_REPRESENTATION = defined(solaris)

proc is_valid_wide_char*(ch: wchar_t): bool =
  when HAVE_NON_UNICODE_WCHAR_T_REPRESENTATION:
    #  Oracle Solaris doesn't use Unicode code points as wchar_t encoding
    #        for non-Unicode locales, which makes values higher than MAX_UNICODE
    #        possibly valid.
    return true
  if Py_UNICODE_IS_SURROGATE(ch):
    #  Reject lone surrogate characters
    return false
  if ch.int > MAX_UNICODE_val:
    #  bpo-35883: Reject characters outside [U+0000; U+10ffff] range.
    #  The glibc mbstowcs() UTF-8 decoder does not respect the RFC 3629,
    #  it creates characters outside the [U+0000; U+10ffff] range:
    #  https://sourceware.org/bugzilla/show_bug.cgi?id=2373
    return false
  return true
