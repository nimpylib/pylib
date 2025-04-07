
import std/tables
export tables

when defined(windows):
  import std/winlean
elif not defined(js):
  import std/posix
import ./types
const DEF_INT = low(int)
when defined(js):
  import ../../jsutils/consts
  template decl_c_int*(name, _; defval) =
    let name* = from_js_const(name, defval)
  {.pragma: ErrnoMapAttr.}
  template ifNotDef(name, body) =
    if name != DEF_INT: body
else:
  import ../../pyconfig/util
  template decl_c_int*(name, includeFile; defval) =
    const name* = from_c_int(name, includeFile, defval)
  {.pragma: ErrnoMapAttr, compileTime.}
  template ifNotDef(name, body) =
    when name != DEF_INT: body

{.pragma: OSErrorInitAttrs, nimcall, noSideEffect.}

var errnomap*{.ErrnoMapAttr.}: Table[cint, proc(): ref PyOSError{.OSErrorInitAttrs.}]
proc default_oserror*(): ref PyOSError{.OSErrorInitAttrs.} =
  new PyOSError

when true: # PyExc_InitState
    template ADD_ERRNO(exc, err){.dirty.} =
        when not declared(err):
          decl_c_int(err, "<errno.h>", DEF_INT)
        ifNotDef err:
           errnomap[cast[cint](err)] = proc(): ref PyOSError = new exc
# The following is just copied from CPython's PyExc_InitState AS-IS.

    ADD_ERRNO(BlockingIOError, EAGAIN);
    ADD_ERRNO(BlockingIOError, EALREADY);
    ADD_ERRNO(BlockingIOError, EINPROGRESS);
    ADD_ERRNO(BlockingIOError, EWOULDBLOCK);
    ADD_ERRNO(BrokenPipeError, EPIPE);
#ifdef ESHUTDOWN
    ADD_ERRNO(BrokenPipeError, ESHUTDOWN);
#endif
    ADD_ERRNO(ChildProcessError, ECHILD);
    ADD_ERRNO(ConnectionAbortedError, ECONNABORTED);
    ADD_ERRNO(ConnectionRefusedError, ECONNREFUSED);
    ADD_ERRNO(ConnectionResetError, ECONNRESET);
    ADD_ERRNO(FileExistsError, EEXIST);
    ADD_ERRNO(FileNotFoundError, ENOENT);
    ADD_ERRNO(IsADirectoryError, EISDIR);
    ADD_ERRNO(NotADirectoryError, ENOTDIR);
    ADD_ERRNO(InterruptedError, EINTR);
    ADD_ERRNO(PermissionError, EACCES);
    ADD_ERRNO(PermissionError, EPERM);
#ifdef ENOTCAPABLE
    # Extension for WASI capability-based security. Process lacks
    # capability to access a resource.
    ADD_ERRNO(PermissionError, ENOTCAPABLE);
#endif
    ADD_ERRNO(ProcessLookupError, ESRCH);
    ADD_ERRNO(TimeoutError, ETIMEDOUT);
#ifdef WSAETIMEDOUT
    ADD_ERRNO(TimeoutError, WSAETIMEDOUT);
#endif
