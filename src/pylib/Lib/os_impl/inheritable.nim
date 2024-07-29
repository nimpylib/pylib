
# XXX: this shall work `when defined(freertos) or defined(zephyr)`
#  but is is meaningful?
import ./private/platform_utils
import ../../pyerrors/oserr

const
  MS_WINDOWS = defined(windows)
  SupportIoctlInheritCtl = (defined(linux) or defined(bsd)) and
                              not defined(nimscript)
  # XXX: hard to express as following in Nim
  # defined(HAVE_SYS_IOCTL_H) && defined(FIOCLEX) && defined(FIONCLEX)

when MS_WINDOWS:
  import std/winlean
else:
  import std/posix
  when SupportIoctlInheritCtl:
    {.push header: "<sys/ioctl.h>".}
    let FIOCLEX{.importc.}: uint
    let FIONCLEX{.importc.}: uint
    {.pop.}

when MS_WINDOWS:
  template with_Py_SUPPRESS_IPH(body) = body # TODO

  proc Py_get_osfhandle_noraise(fd: int): Handle =
    with_Py_SUPPRESS_IPH:
      result = get_osfhandle FileHandle fd
else:
  template with_Py_SUPPRESS_IPH(body) = body

# === get_inheritable ===

template ifRaiseThenErrnoOrN1 =
  if ifRaise:
    raiseErrno()
  return -1

when MS_WINDOWS:
  template ifRaiseThenWinErr0OrN1 =
    if ifRaise:
      # in Windows, raiseOSError raises Windows Error
      raiseOSError OSErrorCode 0
    return -1

  proc get_handle_inheritableImpl(handle: Handle): int =
    var flags: DWORD
    if not bool getHandleInformation(handle, flags.addr):
      ifRaiseThenWinErr0OrN1
    return flags.int and HANDLE_FLAG_INHERIT.int

  proc set_handle_inheritableImpl(handle: Handle, inheritable: bool): int =
    let flags = DWORD:
      if inheritable: HANDLE_FLAG_INHERIT else: 0
    if not bool setHandleInformation(handle, HANDLE_FLAG_INHERIT, flags):
      ifRaiseThenWinErr0OrN1
    return 0

proc get_handle_inheritable*(handle: int): bool{.platformAvail(windows).} =
  bool get_handle_inheritableImpl(Handle handle)

proc set_handle_inheritable*(handle: int, inheritable: bool){.platformAvail(windows).} =
  discard set_handle_inheritableImpl(Handle handle, inheritable)

proc get_inheritable(fd: int, ifRaise: bool): int =
  when MS_WINDOWS:
    let handle = Py_get_osfhandle_noraise fd
    if handle == INVALID_HANDLE_VALUE:
      ifRaiseThenErrnoOrN1
    return get_handle_inheritableImpl(handle)    
  else:
    let flags = fcntl(fd.cint, F_GETFD)
    if flags == -1:
      ifRaiseThenErrnoOrN1
    return int(not bool(flags and FD_CLOEXEC))

proc get_inheritable*(fd: int): bool =
  with_Py_SUPPRESS_IPH:
    result = bool get_inheritable(fd, true)
    # as ifRaise == true, the returned value cannot be -1,
    # but raise Exception on error

# === set_inheritable ===

# works fine on Windows
{.emit:"""/*VARSECTION*/
static const int _defined_O_PATH =
#if defined(O_PATH)
  1
#else
  0
#endif
; // defined shall only occur after #if/#elif
""".}

let
  c_defined_O_PATH{.importc: "_defined_O_PATH", nodecl.}: cint
  defined_O_PATH = bool c_defined_O_PATH


#import std/sysatomics # already export by system

proc Py_atomic_load_relaxed[T](obj: ptr T): T =
  atomicLoadN obj, ATOMIC_RELAXED
proc Py_atomic_store_relaxed[T](obj: ptr T, value: T) =
  atomicStoreN obj, value, ATOMIC_RELAXED

proc set_inheritable(fd: int, inheritable: bool, ifRaise: bool, atomic_flag_works: ptr int): int =
  ##[ there are setInheritable in std/syncio,
   which, however:
    - not available for evary platform.
    - accept Handle which still need get_osfhandle/fcntl to get from `fd`
    - don't try "fast-path" and try fallback
    - don't respect what we do in `block check_errno`
  ]##
  # atomic_flag_works can only be used to make the file descriptor
  #     non-inheritable
  let atomic_fw_nNil = not atomic_flag_works.isNil
  assert not (atomic_fw_nNil and inheritable)
  if atomic_fw_nNil and not inheritable:
    if atomic_flag_works[] == -1:
      let isInheritable = get_inheritable(fd, ifRaise)
      if isInheritable == -1:
        return -1
      atomic_flag_works[] = int bool isInheritable

    if bool atomic_flag_works[]:
      return 0
  when MS_WINDOWS:
    let handle = Py_get_osfhandle_noraise FileHandle fd
    if handle == INVALID_HANDLE_VALUE:
      ifRaiseThenErrnoOrN1
    return set_handle_inheritableImpl(handle, inheritable)
  else:
    let fd = cint fd
    when SupportIoctlInheritCtl:
      var ioctl_works{.global.} = -1
      if ifRaise and Py_atomic_load_relaxed(ioctl_works.addr) != 0:
        # fast-path: ioctl() only requires one syscall
        #[ caveat: raise=0 is an indicator that we must be async-signal-safe
           thus avoid using ioctl() so we skip the fast-path. ]#
        let requested =
          if inheritable: FIONCLEX
          else: FIOCLEX
        let err = ioctl(fd, requested, nil)
        if err == 0:
          if Py_atomic_load_relaxed(ioctl_works.addr) == -1:
            Py_atomic_store_relaxed(ioctl_works.addr, 1)
          return 0

        block check_errno:
          if errno != ENOTTY and errno != EACCES:
            if defined_O_PATH:
              if errno == EBADF:
                #[bpo-44849: On Linux and FreeBSD, ioctl(FIOCLEX) fails with EBADF
                  on O_PATH file descriptors. Fall through to the fcntl()
                  implementation.  ]#
                break check_errno
            ifRaiseThenErrnoOrN1
          else:
            #[Issue #22258: Here, ENOTTY means "Inappropriate ioctl for
              device". The ioctl is declared but not supported by the kernel.
              Remember that ioctl() doesn't work. It is the case on
              Illumos-based OS for example.

              Issue #27057: When SELinux policy disallows ioctl it will fail
              with EACCES. While FIOCLEX is safe operation it may be
              unavailable because ioctl was denied altogether.
              This can be the case on Android.]#
            Py_atomic_store_relaxed(ioctl_works.addr, 0)
          # fallback to fcntl() if ioctl() does not work
    # low-path: fcntl() requires two syscalls
    let flags = fcntl(fd, F_GETFD)
    if flags < 0:
      ifRaiseThenErrnoOrN1
    let new_flags =
      if inheritable: flags and not FD_CLOEXEC
      else: flags or FD_CLOEXEC
    if new_flags == flags:
      # FD_CLOEXEC flag already set/cleared: nothing to do
      return 0
    let res = fcntl(fd, F_SETFD, new_flags)
    if res < 0:
      ifRaiseThenErrnoOrN1
    return 0

proc Py_set_inheritable*(fd: int, inheritable: bool, atomic_flag_works: ptr int): int =
  # used by socket, etc
  set_inheritable(fd, inheritable, true, atomic_flag_works)

proc set_inheritableImpl*(fd: int; inheritable: bool) =
  with_Py_SUPPRESS_IPH:
    discard Py_set_inheritable(fd, inheritable, nil)

proc set_inheritable*(fd: int; inheritable: int|bool) =
  set_inheritableImpl(fd, bool inheritable)
