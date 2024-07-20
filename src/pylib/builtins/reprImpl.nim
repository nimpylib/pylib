
const
  q = '\''
  Q = '"'
  Qq = {Q, q}


func Py_addEscapedChar(result: var string, c: char,
    escapeQuotationMark: static[set[char]] = Qq) =
  ## snippet from CPython-3.14.0-alpha/Objects/bytesobject.c
  ## PyBytes_Repr
  template slash(c: char) =
    result.add '\\'
    result.add c
  template push(c: char) =
    result.add c
  case c
  of '\\': slash '\\'
  of '\t': slash 't'
  of '\n': slash 'n'
  of '\r': slash 'r'
  of escapeQuotationMark:
    slash c
  elif c < ' ' or c.ord > 0x7f:
    const hexdigits = "0123456789abcdef"
    slash 'x'
    let ci = c.ord
    push hexdigits[(ci and 0xf0) shr 4]
    push hexdigits[(ci and 0xf)]
  else:
    when defined(useNimCharEsc):
      if c == '\e': result.add "\\x1b"
      else: push c
    else: push c

func raw_repr(us: string
  ,escapeQuotationMark: static[set[char]] = Qq
  ,escape127: static[bool] = false # if to escape char greater than `\127`
): string =
  template addMayEscape(s: string, c: char) =
    result.Py_addEscapedChar c, escapeQuotationMark
  for c in us:
    template addEscaped =
      result.addMayEscape c
    when escape127:
      addEscaped
    else:
      if c > '\127':
        result.add c  # add non-ASCII utf-8 AS-IS
      else:
        addEscaped

func mycontains(s: string, c: char): bool =
  # NIM-BUG: once using `c in s` when `nimble testC/JS`, it hangs forever
  for i in s:
    if i == c: return true

template implWith(a; rawImpl; arg_escape127: bool): untyped =
  let us = a  # if a is an expr, avoid `a` being evaluated multiply times 
  when defined(singQuotedStr):
    q & rawImpl(us, escape127=arg_escape127) & q
  else:
    if us.mycontains Q:
      q & rawImpl(us, escapeQuotationMark={q}, escape127=arg_escape127) & q
    else:
      if us.mycontains q:
        Q & rawImpl(us, escapeQuotationMark={Q}, escape127=arg_escape127) & Q
      else: # neither ' nor "
        q & rawImpl(us, escape127=arg_escape127) & q

func pyreprImpl*(s: string, escape127: static[bool] = false): string =
  ## Python's `repr`
  ## but returns Nim's string.
  ##
  ##   nim's Escape Char feature can be enabled via `-d:useNimCharEsc`,
  ##     in which '\e' (i.e.'\x1B' in Nim) will be replaced by "\\e"
  ## 
  runnableExamples:
    # NOTE: string literal's `repr` is `system.repr`, as following. 
    assert repr("\"") == "\"\\\"\""   # string literal of "\""
    # use pyrepr for any StringLike and returns a PyStr
    assert pyreprImpl("\"") == "'\"'"
  implWith(s, raw_repr, escape127)

func pyreprbImpl*(s: string): string =
  'b' & s.pyreprImpl(true)
