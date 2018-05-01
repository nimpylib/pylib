test "String operations":
  check "x" * 5 == "xxxxx"
  check 'h' * 2 == "hh"
  check 'h' == "h"
  check 'h' + "ell" + 'o' == "hello"
  check ' '.join(["hello", "world"]) == "hello world"
  check "\t\n ".isspace()
  check "hello world".isalnum()
