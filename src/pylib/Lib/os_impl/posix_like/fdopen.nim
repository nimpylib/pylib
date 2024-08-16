
## this module depends on `io` module

import std/macros

when defined(nimdoc) or defined(js) or defined(nimscript):
  template fdopen*(fd: Positive; x: varargs[untyped]): untyped =
    ## not support JS/NimScript backend
    static: doAssert false, "unsupport JS/NimScript backend"
else:
  import ../../../io
  export io  # for open, write,...

  macro unpackVarargsWith1(callee, arg1: untyped; otherArgs: varargs[untyped]): untyped =
    result = newCall(callee, arg1)
    for i in 0 ..< otherArgs.len:
      result.add otherArgs[i]

  template fdopen*(fd: Positive; x: varargs[untyped]): untyped =
    ## Return an open file object connected to the file descriptor fd.
    ##
    ## This is an alias of the io.open() function and accepts the same arguments.
    ## The only difference is that the first argument of fdopen() must always be an integer.
    bind io.open
    unpackVarargsWith1 io.open, fd, x
    # support kw (will be of kind: nnkExprEqExpr)
