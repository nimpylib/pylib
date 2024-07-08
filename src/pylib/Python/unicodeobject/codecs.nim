
type Py_ssize_t = int
import ./ptr_op, ./char_decl, ./cstring_ptr_op

# CPython-3.14-alpha/stringlib/codecs.h

##  Mask to quickly check whether a C 'size_t' contains a
##    non-ASCII, UTF8-encoded char.
const
  SIZEOF_SIZE_T = sizeof(csize_t)
  PY_LITTLE_ENDIAN = cpuEndian == littleEndian

when (SIZEOF_SIZE_T == 8):
  const
    ASCII_CHAR_MASK* = 0x8080808080808080'u
elif (SIZEOF_SIZE_T == 4):
  const
    ASCII_CHAR_MASK* = 0x80808080
else:
  {.error: "C 'size_t' size should be either 4 or 8!".}
##  10xxxxxx

template IS_CONTINUATION_BYTE*(ch: untyped): untyped =
  ((ch) >= 0x80 and (ch) < 0xC0)

type uintptr_t = uint

const
  ALIGNOF_SIZE_T* = alignof(csize_t)

template Py_IS_ALIGNED*(p: cstring|ptr, a: typeof(ALIGNOF_SIZE_T)): bool =
  (not bool(cast[uintptr_t](p) and (cast[uintptr_t](a) - 1)))

func getMaxChar*[C](): C =
  when C is char: char(0x7f)
  elif C is Py_UCS1: Py_UCS1(0xff)
  elif C is Py_UCS2: Py_UCS2(0xffff)
  elif C is Py_UCS4: Py_UCS4(0x10fff)
  else:
    {.error: "invalid Char type".}

# L23
proc utf8_decode*[STRINGLIB_CHAR](inptr: var (cstring|ptr char); `end`: cstring;
    dest: ptr STRINGLIB_CHAR; outpos: var Py_ssize_t): Py_UCS4 =
  const STRINGLIB_MAX_CHAR = getMaxChar[STRINGLIB_CHAR]()
  type S = typeof(inptr)
  var ch: Py_UCS4
  var s: ptr char = when inptr is cstring: cast[ptr char](inptr) else: inptr
  var p: ptr STRINGLIB_CHAR = dest + outpos
  type cuchar = byte

  template Return =
    inptr = cast[S](s)
    outpos = p - dest
    return ch
  template InvalidContinuation(n) =
    ch = n+1
    Return
  template InvalidStart = InvalidContinuation 0
  while s < `end`:
    ch = cast[cuchar](s[])
    if ch < 0x80:
      ## Fast path for runs of ASCII characters. Given that common UTF-8
      ##  input will consist of an overwhelming majority of ASCII
      ##  characters, we try to optimize for this case by checking
      ##  as many characters as a C 'size_t' can contain.
      ##  First, check if we can do an aligned read, as most CPUs have
      ##  a penalty for unaligned reads.
      ##
      if Py_IS_ALIGNED(s, ALIGNOF_SIZE_T):
        ##  Help register allocation
        var n_s: cstring = s
        var n_p: ptr STRINGLIB_CHAR = p
        while n_s + SIZEOF_SIZE_T <=% `end`:
          ## Read a whole size_t at a time (either 4 or 8 bytes),
          ##  and do a fast unrolled copy if it only contains ASCII
          ##  characters.
          var value: csize_t = cast[ptr csize_t](n_s)[]
          if bool(value and ASCII_CHAR_MASK):
            break
          when PY_LITTLE_ENDIAN:
            n_p[0] = (STRINGLIB_CHAR)(value and 0xFF)
            n_p[1] = (STRINGLIB_CHAR)((value shr 8) and 0xFF)
            n_p[2] = (STRINGLIB_CHAR)((value shr 16) and 0xFF)
            n_p[3] = (STRINGLIB_CHAR)((value shr 24) and 0xFF)
            when SIZEOF_SIZE_T == 8:
              n_p[4] = (STRINGLIB_CHAR)((value shr 32) and 0xFF)
              n_p[5] = (STRINGLIB_CHAR)((value shr 40) and 0xFF)
              n_p[6] = (STRINGLIB_CHAR)((value shr 48) and 0xFF)
              n_p[7] = (STRINGLIB_CHAR)((value shr 56) and 0xFF)
          else:
            when SIZEOF_SIZE_T == 8:
              n_p[0] = (STRINGLIB_CHAR)((value shr 56) and 0xFF)
              n_p[1] = (STRINGLIB_CHAR)((value shr 48) and 0xFF)
              n_p[2] = (STRINGLIB_CHAR)((value shr 40) and 0xFF)
              n_p[3] = (STRINGLIB_CHAR)((value shr 32) and 0xFF)
              n_p[4] = (STRINGLIB_CHAR)((value shr 24) and 0xFF)
              n_p[5] = (STRINGLIB_CHAR)((value shr 16) and 0xFF)
              n_p[6] = (STRINGLIB_CHAR)((value shr 8) and 0xFF)
              n_p[7] = (STRINGLIB_CHAR)(value and 0xFF)
            else:
              n_p[0] = (STRINGLIB_CHAR)((value shr 24) and 0xFF)
              n_p[1] = (STRINGLIB_CHAR)((value shr 16) and 0xFF)
              n_p[2] = (STRINGLIB_CHAR)((value shr 8) and 0xFF)
              n_p[3] = (STRINGLIB_CHAR)(value and 0xFF)
          inc(n_s, SIZEOF_SIZE_T)
          inc(n_p, SIZEOF_SIZE_T)
        s = cast[ptr char](n_s)
        p = cast[ptr Py_UCS4](n_p)
        if s == `end`:
          break
        ch = cast[cuchar](s[])
      if ch < 0x80:
        inc(s)
        p[] = ch
        inc(p)
        continue
    if ch < 0xE0:
      ##  \xC2\x80-\xDF\xBF -- 0080-07FF
      var ch2: Py_UCS4
      if ch < 0xC2:
        ##  invalid sequence
        ##                 \x80-\xBF -- continuation byte
        ##                 \xC0-\xC1 -- fake 0000-007F
        InvalidStart
      if `end` - s < 2:
        ##  unexpected end of data: the caller will decide whether
        ##                    it's an error or not
        break
      ch2 = cast[cuchar](s[1])
      if not IS_CONTINUATION_BYTE(ch2):
        InvalidContinuation 1
      ch = (ch shl 6) + ch2 - ((0xC0 shl 6) + 0x80)
      assert((ch > 0x007F) and (ch <= 0x07FF))
      inc(s, 2)
      if STRINGLIB_MAX_CHAR <= 0x007F or
          (STRINGLIB_MAX_CHAR < 0x07FF and ch > STRINGLIB_MAX_CHAR):
        # Out-of-range
        Return
      p[] = ch
      inc(p)
      continue
    if ch < 0xF0:
      ##  \xE0\xA0\x80-\xEF\xBF\xBF -- 0800-FFFF
      var
        ch2: Py_UCS4
        ch3: Py_UCS4
      if `end` - s < 3:
        ##  unexpected end of data: the caller will decide whether
        ##                    it's an error or not
        if `end` - s < 2:
          break
        ch2 = cast[cuchar](s[1])
        if not IS_CONTINUATION_BYTE(ch2) or
            (if ch2 < 0xA0: ch == 0xE0 else: ch == 0xED):
          InvalidContinuation 1
        break
      ch2 = cast[cuchar](s[1])
      ch3 = cast[cuchar](s[2])
      if not IS_CONTINUATION_BYTE(ch2):
        ##  invalid continuation byte
        InvalidContinuation 1
      if ch == 0xE0:
        if ch2 < 0xA0:
          InvalidContinuation 1
      elif ch == 0xED and ch2 >= 0xA0:
        ## Decoding UTF-8 sequences in range \xED\xA0\x80-\xED\xBF\xBF
        ##  will result in surrogates in range D800-DFFF. Surrogates are
        ##  not valid UTF-8 so they are rejected.
        ##  See https://www.unicode.org/versions/Unicode5.2.0/ch03.pdf
        ##  (table 3-7) and http://www.rfc-editor.org/rfc/rfc3629.txt
        InvalidContinuation 1
      if not IS_CONTINUATION_BYTE(ch3):
        ##  invalid continuation byte
        InvalidContinuation 2
      ch = (ch shl 12) + (ch2 shl 6) + ch3 - ((0xE0 shl 12) + (0x80 shl 6) + 0x80)
      assert((ch > 0x07FF) and (ch <= 0xFFFF))
      inc(s, 3)
      if STRINGLIB_MAX_CHAR <= 0x07FF or
          (STRINGLIB_MAX_CHAR < 0xFFFF and ch > STRINGLIB_MAX_CHAR):
        Return
      p[] = ch
      inc(p)
      continue
    if ch < 0xF5:
      ##  \xF0\x90\x80\x80-\xF4\x8F\xBF\xBF -- 10000-10FFFF
      var
        ch2: Py_UCS4
        ch3: Py_UCS4
        ch4: Py_UCS4
      if `end` - s < 4:
        ##  unexpected end of data: the caller will decide whether
        ##                    it's an error or not
        if `end` - s < 2:
          break
        ch2 = cast[cuchar](s[1])
        if not IS_CONTINUATION_BYTE(ch2) or
            (if ch2 < 0x90: ch == 0xF0 else: ch == 0xF4):
          InvalidContinuation 1
        if `end` - s < 3:
          break
        ch3 = cast[cuchar](s[2])
        if not IS_CONTINUATION_BYTE(ch3):
          InvalidContinuation 2
        break
      ch2 = cast[cuchar](s[1])
      ch3 = cast[cuchar](s[2])
      ch4 = cast[cuchar](s[3])
      if not IS_CONTINUATION_BYTE(ch2):
        ##  invalid continuation byte
        InvalidContinuation 1
      if ch == 0xF0:
        if ch2 < 0x90:
          InvalidContinuation 1
      elif ch == 0xF4 and ch2 >= 0x90:
        ##  invalid sequence
        ##                    \xF4\x90\x80\x80- -- 110000- overflow
        InvalidContinuation 1
      if not IS_CONTINUATION_BYTE(ch3):
        ##  invalid continuation byte
        InvalidContinuation 2
      if not IS_CONTINUATION_BYTE(ch4):
        ##  invalid continuation byte
        InvalidContinuation 3
      ch = (ch shl 18) + (ch2 shl 12) + (ch3 shl 6) + ch4 -
          ((0xF0 shl 18) + (0x80 shl 12) + (0x80 shl 6) + 0x80)
      assert((ch > 0xFFFF) and (ch <= 0x10FFFF))
      inc(s, 4)
      if STRINGLIB_MAX_CHAR <= 0xFFFF or
          (STRINGLIB_MAX_CHAR < 0x10FFFF and ch > STRINGLIB_MAX_CHAR):
        Return
      p[] = ch
      inc(p)
      continue
    InvalidStart
  ch = 0
  Return
