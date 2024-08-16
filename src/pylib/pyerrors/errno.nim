
when defined(js):
    template errno*: cint{.error: "get errno from Error's attr".} = 0
elif defined(windows):
    # std/posix has defined `errno`
    var errno*{.importc, header: "<errno.h>".}: cint
else:
  import std/posix
  export errno
