
# translated from Python/fileutils.c

import ./wchar_t
export Py_mbstowcs

const
  Py_FORCE_UTF8_LOCALE* = defined(android) or defined(vxworks)  ##[
    CPython/Include/pyport.h:
    Use UTF-8 as the filesystem encoding.
      See PyUnicode_DecodeFSDefaultAndSize(), PyUnicode_EncodeFSDefault(),
      Py_DecodeLocale() and Py_EncodeLocale().]##
  Py_FORCE_UTF8_FS_ENCODING* = Py_FORCE_UTF8_LOCALE or defined(macosx)

when not (Py_FORCE_UTF8_FS_ENCODING) and not defined(windows):
  import ../private/encoding_norm
  import std/posix  # setlocale

  #[ Workaround FreeBSD and OpenIndiana locale encoding issue with the C locale
   and POSIX locale. nl_langinfo(CODESET) announces an alias of the
   ASCII encoding, whereas mbstowcs() and wcstombs() functions use the
   ISO-8859-1 encoding. The problem is that os.fsencode() and os.fsdecode() use
   locale.getpreferredencoding() codec. For example, if command line arguments
   are decoded by mbstowcs() and encoded back by os.fsencode(), we get a
   UnicodeEncodeError instead of retrieving the original byte string.

   The workaround is enabled if setlocale(LC_CTYPE, NULL) returns "C",
   nl_langinfo(CODESET) announces "ascii" (or an alias to ASCII), and at least
   one byte in range 0x80-0xff can be decoded from the locale encoding. The
   workaround is also enabled on error, for example if getting the locale
   failed.

   On HP-UX with the C locale or the POSIX locale, nl_langinfo(CODESET)
   announces "roman8" but mbstowcs() uses Latin1 in practice. Force also the
   ASCII encoding in this case.

   Values of force_ascii:

       1: the workaround is used: Py_EncodeLocale() uses
          encode_ascii_surrogateescape() and Py_DecodeLocale() uses
          decode_ascii()
       0: the workaround is not used: Py_EncodeLocale() uses wcstombs() and
          Py_DecodeLocale() uses mbstowcs()
      -1: unknown, need to call check_force_ascii() to get the value
  ]#
  var `PyRuntime.fileutils.force_ascii` = -1 # _PyRuntime.fileutils.force_ascii
  template force_ascii*: untyped = `PyRuntime.fileutils.force_ascii`

  proc check_force_ascii*(): bool =
    block noerror:
      let loc = setlocale(LC_CTYPE, nil)
      if loc == nil:
        break noerror
      if loc != cstring"C" and loc != cstring"POSIX":
        ##  the LC_CTYPE locale is different than C and POSIX
        return false
      when declared(nl_langinfo) and declared(CODESET):
        let codeset: cstring = nl_langinfo(CODESET)
        if codeset == nil or codeset[0] == '\x00':
          ##  CODESET is not set or empty
          break noerror
        ##  longest name: "iso_646.irv_1991\0"
        let encoding = Py_normalize_encoding($codeset)
        when defined(hpux):
          if encoding == "roman8":
            var ch: array[2, cchar]
            var wch: wchar_t
            var res: csize_t
            ch[0] = cast[cchar](0xA7)
            res = Py_mbstowcs(addr(wch), cast[cstring](addr(ch[0])), 1)
            if res != DECODE_ERROR and wch == wchar_t('\xA7'):
              # On HP-UX with C locale or the POSIX locale,
              # nl_langinfo(CODESET) announces "roman8", whereas mbstowcs() uses
              # Latin1 encoding in practice. Force ASCII in this case.
              #
              # Roman8 decodes 0xA7 to U+00CF. Latin1 decodes 0xA7 to U+00A7.
              return true
        else:
          const ascii_aliases = ["ascii", "646",
              "ansi_x3.4_1968", "ansi_x3.4_1986", "ansi_x3_4_1968", "cp367",
              "csascii", "ibm367", "iso646_us", "iso_646.irv_1991", "iso_ir_6",
              "us", "us_ascii"]
          let is_ascii = encoding in ascii_aliases
          if not is_ascii:
            ##  nl_langinfo(CODESET) is not "ascii" or an alias of ASCII
            return false
          var i: cuint = 0x80
          while i <= 0xff:
            var ch: array[2, char]
            var wch: array[1, wchar_t]
            var res: csize_t
            var uch = cast[cchar](i)
            ch[0] = cast[char](uch)
            res = Py_mbstowcs(wch[0].addr, cast[cstring](ch[0].addr), 1)
            if res != DECODE_ERROR:
              # decoding a non-ASCII character from the locale encoding succeed:
              #   the locale encoding is not ASCII, force ASCII
              return true
            inc(i)
          # None of the bytes in the range 0x80-0xff can be decoded from the
          #       locale encoding: the locale encoding is really ASCII
        return false
      else:
        # nl_langinfo(CODESET) is not available: always force ASCII
        return true
    # if an error occurred, force the ASCII encoding
    return true

  proc Py_GetForceASCII*(): bool =
    if force_ascii == -1:
      force_ascii = typeof(force_ascii) check_force_ascii()
    return bool force_ascii

  proc Py_ResetForceASCII*() =
    force_ascii = -1
else:
  proc Py_GetForceASCII*(): bool =
    return false
  proc Py_ResetForceASCII*() = discard
