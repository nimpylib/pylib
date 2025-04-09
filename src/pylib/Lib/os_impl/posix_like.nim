## posixmodule, also mimic posix api for Windows

import ./posix_like/[
  fdopen, open_close, lseek, seek_consts, truncate, stat, scandirImpl, mkrmdir, unlink,
  rename, isatty, links, utime, get_id, chmods, umaskImpl
]

export seek_consts except toCSEEK
export stat except statAttr
export
  fdopen, open_close, lseek, truncate, scandirImpl, mkrmdir, unlink,
  rename, isatty, links, utime, get_id, chmods, umaskImpl
