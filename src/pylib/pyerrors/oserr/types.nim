
import ./oserror_decl
export oserror_decl

template decl(exc; sup){.dirty.} =
  type exc* = object of sup

template decl(exc){.dirty.} = decl(exc, oserror_decl.PyOSError)

decl BlockingIOError
decl ConnectionError
decl ChildProcessError
decl BrokenPipeError, ConnectionError
decl ConnectionAbortedError, ConnectionError
decl ConnectionRefusedError, ConnectionError
decl ConnectionResetError, ConnectionError

decl FileExistsError
decl FileNotFoundError
decl IsADirectoryError
decl NotADirectoryError
decl InterruptedError
decl PermissionError
decl ProcessLookupError
decl TimeoutError

