
when defined(windows):
  type wchar_t*{.importc, header: "<wchar.h>".} = uint16
else:
  type wchar_t*{.importc, header: "<wchar.h>".} = uint32

func ord*(wc: wchar_t): int = int(wc)

template allocWcharArr*[I](n: I): ptr wchar_t =
  cast[ptr wchar_t](alloc(n * I(sizeof(wchar_t))))
template deallocWcArr*(p: ptr wchar_t) = p.dealloc()

type
  mbstate_t*{.importc, header: "wchar.h>"} = object

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

type PWc = (var wchar_t)|(ptr wchar_t)

#[ size_t mbstowcs(
  wchar_t * __restrict__ _Dest,
  const char * __restrict__ _Source,size_t _MaxCount); ]#
proc mbstowcs(dest: ptr wchar_t, src: cstring, maxcount: csize_t): csize_t{.
  importc, header: "<stdlib.h>".}

#[size_t mbrtowc( wchar_t* pwc, const char* s, size_t n, mbstate_t* ps );]#
proc mbrtowc(wc: PWc, src: cstring, maxcount: csize_t,
  mbs: var mbstate_t): csize_t{.importc, header: "<wchar.h>".}

const HAVE_MBRTOWC* = true

# mbstowcs() and mbrtowc() errors
const
  DECODE_ERROR* = cast[csize_t](-1)
  INCOMPLETE_CHARACTER* = cast[csize_t](-2)

proc `[]`*(p: ptr wchar_t, i: csize_t): wchar_t =
  (cast[ptr wchar_t](cast[csize_t](p)+i))[]
proc `[]`*(p: ptr wchar_t, i: int): wchar_t =
  (cast[ptr wchar_t](cast[int](p)+i))[]

proc `[]=`*(p: ptr wchar_t, i: csize_t, val: wchar_t) =
  (cast[ptr wchar_t](cast[csize_t](p)+i))[]=val
template inc*(p: var ptr wchar_t, i = 1) =
  p = (cast[ptr wchar_t](cast[csize_t](p)+i))

# fileutils.c

# L143 _Py_mbstowcs 
proc Py_mbstowcs*(dest: ptr wchar_t; src: cstring; n: csize_t): csize_t =
  var count: csize_t = mbstowcs(dest, src, n)
  if dest != nil and count != DECODE_ERROR:
    var i: csize_t = 0
    while i < count:
      var ch: wchar_t = dest[i]
      if not is_valid_wide_char(ch):
        return DECODE_ERROR
      inc(i)
  return count

# L160 _Py_mbrtowc
proc Py_mbrtowc*(wc: PWc; src: cstring; n: csize_t,
    mbs: var mbstate_t): csize_t =
  when wc is ptr:
    assert wc != nil
  var count: csize_t = mbrtowc(wc, src, n, mbs)
  if count != 0 and count != DECODE_ERROR and count != INCOMPLETE_CHARACTER:
    if not is_valid_wide_char(when wc is ptr: wc[] else: wc):
      return DECODE_ERROR
  return count

