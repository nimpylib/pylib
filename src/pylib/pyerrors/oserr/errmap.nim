
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
  template asgn_cint(name, val){.used.} =
    let name = val
  template decl_c_intImpl(variable, name, _; defval) =
    let variable = from_js_const(name, defval)
  {.pragma: ErrnoMapAttr.}
  template ifHasErr(name, body) =
    if name != DEF_INT: body
else:
  import ../../pyconfig/util
  template asgn_cint(name, val){.used.} =
    const name = val
  template decl_c_intImpl(variable, name, includeFile; defval) =
    const variable = from_c_int(name, includeFile, defval)
  {.pragma: ErrnoMapAttr, compileTime.}
  template ifHasErr(name, body) =
    when name != DEF_INT: body

template decl_c_int*(name, includeFile; defval) =
  bind decl_c_intImpl
  decl_c_intImpl(name, name, includeFile, defval)
  export name

{.pragma: OSErrorInitAttrs, nimcall, noSideEffect.}

var errnomap*{.ErrnoMapAttr.}: Table[cint, proc(): ref PyOSError{.OSErrorInitAttrs.}]
proc default_oserror*(): ref PyOSError{.OSErrorInitAttrs.} =
  new PyOSError

template decl_err(err){.dirty.} =
  decl_c_int(err, "<errno.h>", DEF_INT)

template decl_err_cint(err){.dirty.} =
  when declared(err):
    export err
  else:
    decl_c_intImpl(`n err`, name, "<errno.h>", DEF_INT)
    template asgExp =
      asgn_cint err, cast[cint](`n err`)
      export err
    when defined(js): asgExp
    else:
      ifHasErr `n err`: asgExp

decl_err_cint E2BIG
decl_err_cint ENOEXEC
decl_err_cint EBADF
decl_err_cint ENOMEM
decl_err_cint EXDEV
decl_err_cint EMFILE
decl_err_cint ENOSPC
decl_err_cint ENOTEMPTY
decl_err_cint EILSEQ
decl_err_cint EINVAL

when true: # PyExc_InitState
    template ADD_ERRNO(exc, err){.dirty.} =
        when not declared(err):
          decl_err(err)
        else:
          export err
        ifHasErr err:
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
