## posixmodule, also mimic posix api for Windows

import ./posix_like/[
  fdopen, open_close, truncate, stat, scandirImpl, mkrmdir, unlink,
  rename, isatty, links
]

export
  fdopen, open_close, truncate, stat, scandirImpl.scandir, mkrmdir, unlink,
  rename, isatty, links
