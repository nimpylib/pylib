import ./clike
import ./errnos
template whenDefErrno*(err; body) =
  bind CLike
  when not CLike: body
  else:
    const errS = astToStr(err)
    {.emit: "\n#ifdef " & errS & '\n'.}
    body
    {.emit: "\n#endif\n".}

template forErrno*(err; body) =
  bind whenDefErrno, Errno
  for err{.inject.} in Errno:
    if err == Errno.E_SUCCESS: continue
    whenDefErrno err:
      body
