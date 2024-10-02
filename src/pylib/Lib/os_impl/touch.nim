
import ./posix_like
import ./consts

proc touch*(s: string; mode=0o666, exist_ok=true) =
  ## EXT.
  ## used by pathlib
  ## Create this file with the given access mode, if it doesn't exist.

  if exist_ok:
      # First try to bump modification time
      # Implementation note: GNU touch uses the UTIME_NOW option of
      # the utimensat() / futimens() functions.
      try:
          utime(s)
          return
      except OSError:
          # Avoid exception chaining
          discard
  var flags = O_CREAT | O_WRONLY
  if not exist_ok:
      flags |= O_EXCL
  let fd = open(s, flags, mode)
  close(fd)

