
import ./common
import ./reimporter

iterator split_whitespace*(pystr: PyBytes, maxsplit = -1): PyBytes =
  for i in split_whitespace[PyBytes](pystr, maxsplit=maxsplit):
    yield i

proc split_whitespace*(pystr: PyBytes, maxsplit = -1): PyList[PyBytes] =  
  split_whitespace[PyBytes](pystr, maxsplit=maxsplit)
