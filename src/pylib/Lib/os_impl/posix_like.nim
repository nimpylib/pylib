## posixmodule, also mimic posix api for Windows

import ./posix_like/[
  fdopen, open_close, truncate, stat, scandirImpl, mkrmdir, unlink,
  rename
]

export
  fdopen, open_close, truncate, stat, scandirImpl.scandir, mkrmdir, unlink,
  rename
