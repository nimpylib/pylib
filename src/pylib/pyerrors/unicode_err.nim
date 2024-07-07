
import std/strutils

type
  UnicodeError* = object of ValueError
  UnicodeDecodeError* = object of UnicodeError

func newUnicodeDecodeError*(
  codec: string, src: char,
  start, stop: int, reason: string
): ref UnicodeDecodeError =
  let stop = stop - 1
  var msg = "'$#' codec can't decode " % codec
  if stop == start:
    msg.add "byte "
    msg.add $toHex(ord(src))
    msg.add " in position "
    msg.add $stop
  else:
    msg.add "bytes "
    msg.add " in position "
    msg.add "$#-$#".format(start, stop)
  msg.add ": "
  msg.add reason
  newException(UnicodeDecodeError, msg)

func newUnicodeDecodeError*(
  codec: string, src: string,
  start, stop: int, reason: string
): ref UnicodeDecodeError =
  newUnicodeDecodeError(codec, src[stop], start, stop, reason)
