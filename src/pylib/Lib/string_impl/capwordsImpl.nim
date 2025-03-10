

template genCapwords*(Arg, Res, split, split2, capitalize, strip){.dirty.} =
  func capwords*(a: Arg): Res =
    ## Mimics Python string.capwords(s) -> str:
    ## 
    ## Runs of whitespace characters are replaced by a single space
    ##  and leading and trailing whitespace are removed.
    var res = newStringOfCap (when compiles(a.byteLen): a.byteLen else: a.len)
    for word in split(a):
      res.add capitalize(word)
      res.add ' '
    res = strip(res)
    res


  func capwords*(a: Arg, sep: Arg): Res =
    ## Mimics Python string.capwords(s, sep) -> str:
    ## 
    ## Split the argument into words using split, capitalize each
    ##  word using `capitalize`, and join the capitalized words using
    ##  `join`. `sep` is used to split and join the words.
    let ssep = $sep
    var res = newStringOfCap (when compiles(a.byteLen): a.byteLen else: a.len)
    for word in split2(a, ssep):
      res.add capitalize(word)
      res.add ssep
    res.setLen res.len - ssep.len
    res
