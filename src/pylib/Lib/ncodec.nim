## EXT. Nim's codec.
##  not the same as Python's codec

import std/encodings
import std/unicode
import ../pyerrors/lkuperr
export LookupError

# XXX: not take effect yet
type EncErrors*{.pure.} = enum
  strict  ## - raise a ValueError error (or a subclass)
  ignore  ## - ignore the character and continue with the next
  replace ##[  - replace with a suitable replacement character;
             Python will use the official U+FFFD REPLACEMENT
             CHARACTER for the builtin Unicode codecs on
             decoding and "?" on encoding.]##
  surrogateescape   ## - replace with private code points U+DCnn.
  xmlcharrefreplace ## - Replace with the appropriate XML
                      ##   character reference (only for encoding).
  backslashreplace  ## - Replace with backslashed escape sequences.
  namereplace       ## - Replace with \N{...} escape sequences
                      ##   (only for encoding).

type
  CvtRes = tuple[data: string, len: int]
  EncoderCvt = proc (s: string): CvtRes
  EncoderClose = proc ()
  NCodecInfo* = object
    name*: string
    errors*: string
    encode*, decode*: EncoderCvt
    close*: EncoderClose

const
  DefErrors* = "strict"

# patch
# nim's implementation assumed iconv_open returns NULL on failure,
#  which is `(iconv_t) -1` in fact.
const openFixed = (NimMajor, NimMinor, NimPatch) > (2, 1, 1)
proc encodings_open(
    destEncoding = "UTF-8"; srcEncoding = "CP1252";
    errors=DefErrors  # XXX: just ignored
  ): EncodingConverter =
  when openFixed or defined(windows):
    encodings.open(destEncoding=destEncoding, srcEncoding=srcEncoding)
  else:
    let cvt = encodings.open(destEncoding=destEncoding, srcEncoding=srcEncoding)
    if cvt == cast[EncodingConverter](-1):
      raise newException(EncodingError,
        "cannot create encoding converter from " &
        srcEncoding & " to " & destEncoding)
    cvt

const innerEnc = "UTF-8"
func initNCodecInfo*(encoding: string, errors = DefErrors): NCodecInfo =
  result.name = encoding
  var iEncCvt, oEncCvt: EncodingConverter
  try:
    iEncCvt = encodings_open(
      destEncoding = innerEnc,
      srcEncoding = encoding,
      errors = errors
    )
    oEncCvt = encodings_open(
      destEncoding = encoding,
      srcEncoding = innerEnc,
      errors = errors
    )
  except EncodingError:
    raise newException(LookupError, "unknown encoding: " & encoding)
  result.encode = proc (s: string): CvtRes =
    result.data = oEncCvt.convert(s)
    result.len = s.runeLen
  result.decode = proc(s: string): CvtRes =
    result.data = iEncCvt.convert(s)
    result.len = s.len
  result.close = proc() =
    oEncCvt.close()
    iEncCvt.close()

