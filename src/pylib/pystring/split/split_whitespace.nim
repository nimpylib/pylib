
import ./common
import ./reimporter

iterator split_whitespace*(pystr: PyStr, maxsplit = -1): PyStr =
  for i in split_whitespace[PyStr](pystr, maxsplit=maxsplit):
    yield i

proc split_whitespace*(pystr: PyStr, maxsplit = -1): PyList[PyStr] =  
  split_whitespace[PyStr](pystr, maxsplit=maxsplit)
