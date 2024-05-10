
proc raw_repr(us: string
  ,e1: static[bool] = false # if skip(not escape) `'`(single quotation mark)
  ,e2: static[bool] = false # if skip(not escape) `"`(double quotation mark)
): string =
  template add12(s: string, c: char) =
    when e1:
      if c == '\'':
        result.add '\''
        continue
    when e2:
      if c == '"':
        result.add '"'
        continue
    result.addEscapedChar c
  for c in us:
    if c > '\127':
      result.add c  # add non-ASCII utf-8 AS-IS
    else:
      when defined(useNimCharEsc): result.add12 c
      else:
        if c == '\e': result.add "\\x1b"
        else: result.add12 c

template implWith(a; rawImpl): untyped =
  let us = a  # if a is an expr, avoid `a` being evaluated multiply times 
  when defined(singQuotedStr):
    '\'' & rawImpl(us) & '\''
  else:
    if '"' in us:
      '\'' & rawImpl(us, e2 = true) & '\''
    else:
      if '\'' in us:
        '"' & rawImpl(us, e1 = true) & '"'
      else: # neither ' nor "
        '\'' & rawImpl(us) & '\''

func pyreprImpl*(s: string): string =
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
  implWith(s, raw_repr)
