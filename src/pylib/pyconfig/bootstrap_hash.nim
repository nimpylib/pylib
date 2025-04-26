

when defined(linux):
  import ./util
  AC_LINK_IFELSE have_getrandom, false:
    proc getrandom(buf: pointer, buflen: uint, flags: cuint): int{.importc,
      header: "<sys/random.h>".}
    var buffer: char
    let buflen = uint 1
    let flags = cuint 0
    # ignore the result, Python checks for ENOSYS at runtime
    discard getrandom(addr buffer, buflen, flags)
  
  template syscalChkAndExport(def){.dirty.} =
    AC_LINK_IFELSE have_getrandom_syscall, false:
      def
      var buffer: char
      let buflen = uint 1
      let flags{.importc: "GRND_NONBLOCK", header: "<sys/random.h>".}: cint
      # ignore the result, Python checks for ENOSYS at runtime
      discard syscall(SYS_getrandom, addr buffer, buflen, flags)
    when have_getrandom_syscall:
      def

  syscalChkAndExport:
    let SYS_getrandom* {.importc, header: "<sys/syscall.h>".}: clong
    const syscallHeader = """#include <unistd.h>
    #include <sys/syscall.h>"""
    proc syscall*(n: clong): clong {.
        importc: "syscall", varargs, header: syscallHeader.}
else:
  const
    have_getrandom* = false
    have_getrandom_syscall* = false

const py_getrandom* = have_getrandom or have_getrandom_syscall
