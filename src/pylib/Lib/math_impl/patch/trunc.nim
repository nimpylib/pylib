 
func uncheckedTruncToInt*[I: SomeInteger](x: SomeFloat): I =
  ## do not check for nans and infinities
  I x
