
import ../pystring

const
  ascii_lowercase* = str "abcdefghijklmnopqrstuvwxyz"
  ascii_uppercase* = str "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  ascii_letters* = ascii_lowercase + ascii_uppercase
  digits* = str "0123456789"
  hexdigits* = str "0123456789abcdefABCDEF"
  octdigits* = str "01234567"
  punctuation* = str """!"#$%&\'()*+,-./:;<=>?@[\\]^_`{|}~"""
  whitespace* = str " \t\n\r\x0b\x0c"
  printable* = digits + ascii_letters + punctuation + whitespace


func capwords*(a: StringLike): PyStr =
  ## Mimics Python string.capwords(s) -> str:
  ## 
  ## Runs of whitespace characters are replaced by a single space
  ##  and leading and trailing whitespace are removed.
  for word in pystring.split(str(a)):
    result += pystring.capitalize(word)
    result += ' '
  result = pystring.strip(result)

func capwords*(a: StringLike, sep: StringLike): PyStr =
  ## Mimics Python string.capwords(s, sep) -> str:
  ## 
  ## Split the argument into words using split, capitalize each
  ##  word using `capitalize`, and join the capitalized words using
  ##  `join`. `sep` is used to split and join the words.
  let ssep = $sep
  for word in pystring.split(str(a), ssep):
    result += pystring.capitalize(word)
    result += ssep

