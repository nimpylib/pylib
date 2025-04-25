
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
  template ifHasErr(name: int; body) =
    if name != DEF_INT: body
else:
  import ../../pyconfig/util
  template asgn_cint(name, val){.used.} =
    const name = val
  template decl_c_intImpl(variable, name, includeFile; defval) =
    const variable = from_c_int(name, includeFile, defval)
  {.pragma: ErrnoMapAttr, compileTime.}
  template ifHasErr(name: int; body) =
    when name != DEF_INT: body

template decl_c_int*(name, includeFile; defval) =
  bind decl_c_intImpl
  decl_c_intImpl(name, name, includeFile, defval)
  export name

{.pragma: OSErrorInitAttrs, nimcall, noSideEffect.}

var errnomap*{.ErrnoMapAttr.}: Table[cint, proc(): ref PyOSError{.OSErrorInitAttrs.}]
proc default_oserror*(): ref PyOSError{.OSErrorInitAttrs.} =
  new PyOSError

template decl_err(variable, err){.dirty.} =
  decl_c_intImpl(variable, err, "<errno.h>", DEF_INT)

template isConst(e): bool = compiles((const _=err))

template asgExp(err; nerr: int; doSth) =
  asgn_cint err, cast[cint](nerr)
  export err
  doSth

template decl_err_cint(err, doIfDefined){.dirty.} =
  ## generate `const err*: cint = ...` if err defined in `<errno.h>`
  bind asgExp
  when isConst(err):
    export err
    doIfDefined
  else:
    decl_err(`n err`, err)
    when defined(js): asgExp err, `n err`, doIfDefined
    else:
      ifHasErr `n err`: asgExp err, `n err`, doIfDefined

template decl_err_cint(err) =
  ## generate `const err*: cint = ...` if err defined in `<errno.h>`
  bind decl_err_cint
  decl_err_cint(err): discard

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
        decl_err_cint err:
           errnomap[err] = proc(): ref PyOSError = new exc
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
