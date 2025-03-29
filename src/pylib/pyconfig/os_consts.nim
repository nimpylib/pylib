
import ./util

template o(name) =
  const `bare name` = from_c_int(name, "<fcntl.h>")
  when `bare name` != int.low:
    const name* = cint `bare name`

o O_ASYNC
o O_DIRECT
o O_DIRECTORY
o O_NOFOLLOW
o O_NOATIME
o O_PATH
o O_TMPFILE
o O_SHLOCK
o O_EXLOCK
