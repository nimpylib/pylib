## posixmodule, also mimic posix api for Windows

import ./posix_like/[
  fdopen, open_close, truncate, stat, scandir
]

export fdopen, open_close, truncate, stat, scandir
