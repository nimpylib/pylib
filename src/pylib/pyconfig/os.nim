
import ./util
const
  DEFAULT_DIR_FD* = from_c_int(AT_FDCWD, "<fcntl.h>", -100)
  AT_SYMLINK_NOFOLLOW* = from_c_int(AT_SYMLINK_NOFOLLOW, "<fcntl.h>", 0x100)
