
import ./clike
when CLike:
  var errno*{.importc: "errno", header: "<errno.h>".}: cint
else:
  var errno*{.threadvar.}: cint

var staticErrno*{.compileTime.}: cint  ## used compile time
