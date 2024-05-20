
# imported by Lib/io

when defined(posix):
  proc isatty(fildes: cint): cint {.
    importc: "isatty", header: "<unistd.h>".}
else:
  proc isatty(fildes: cint): cint {.
    importc: "_isatty", header: "<io.h>".}

func isatty*(fd: int): bool =
  isatty(fd.cint) != 0
