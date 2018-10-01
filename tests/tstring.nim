test "String operations":
  check "x" * 5 == "xxxxx"
  check 'h' * 2 == "hh"
  check 'h' == "h"
  check 'h' + "ell" + 'o' == "hello"
  check '0' + "1" + '2' == "012"
  check ' '.join(["hello", "world"]) == "hello world"
  check "\t\n ".isspace()

  check "hello".isalnum()
  check "01234".isalnum()

  check "hello world".capwords == "Hello World"
  check "01234".capwords == "01234"

  check "a".center(9) == "    a    "

  check "HELLO WORLD".casefold == "hello world"

  check " ".join([1, 2, 3, 4, 5, 6, 7, 8, 9]) == "1 2 3 4 5 6 7 8 9"
  check " ".join(['a', 'b', 'c', 'd', 'e']) == "a b c d e"

  check " ".isspace
  check "                   ".isspace

  check "hello world".index("w") == 6

  check "a" or "b" == "a"
  check "" or "b" == "b"
