
const CLike* = defined(c) or defined(cpp) or defined(objc)

template clikeOr*(inCLike, b): untyped =
  # for nimvm-able expr
  when nimvm: b
  else:
    when CLike: inCLike
    else: b

