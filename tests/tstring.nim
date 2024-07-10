test "str operations":
  check "x" * 5 == "xxxxx"
  check 'h' * 2 == "hh"
  check 'h' == "h"
  check 'h' + "ell" + 'o' == "hello"
  check '0' + "1" + '2' == "012"
  check ' '.join(["hello", "world"]) == "hello world"
  check "\t\n ".isspace()

test "str index":
  let mixedStr = str("aδ_Δ")
  check mixedStr[-1] == str("Δ")
  check mixedStr[1] == str("δ")
  check mixedStr[2] == str("_")


test "str methods":
  checkpoint "split whitespace"
  template eqList(a, b) =
    check @a == @b
  eqList str("a\u2000 \u2000b").split(), [str("a"),str("b")] ## \u2000 is of Unicode spaces
  eqList str("1   2   3").split(maxsplit=1), [str("1"), str("2   3")]

  checkpoint "split with char sep"
  eqList str("1 _2_   3").split('_'), [str"1 ", str"2", str"   3"]

  checkpoint "split with str sep"
  eqList "1 _2_   3".split("_ "), [str"1 _2", str"  3"]

  checkpoint "rsplit"
  eqList str("abc.list.txt").rsplit('.', 1), [str"abc.list", str"txt"]

  checkpoint "splitlines"
  eqList str("1\u20282").splitlines(), [str"1", str"2"]
  eqList str("1\u20282").splitlines(keepends=True), [str("1\u2028"), str"2"]

  check "Hi U".istitle()

  check "HELLO WORLD".isupper()
  check not "c A".isupper()
  check "hello ".islower()

  block:
    let u = str("ǉ") # \u01c9
    check u.title() == "ǈ"  # \u01c8
  
  check str("ῃ").title() == "ῌ" # \u1fcc
  check str("aNd What").title() == "And What"

  check capitalize("aBΔ") == "Abδ"
  check "HELLO WORLD".casefold() == "hello world"

  check "a".center(9) == "    a    "
  check "a".center(1) == "a"

  check " ".join([1, 2, 3, 4, 5, 6, 7, 8, 9]) == "1 2 3 4 5 6 7 8 9"
  check " ".join(['a', 'b', 'c', 'd', 'e']) == "a b c d e"

  check " ".isspace
  check "                   ".isspace

  check "hello world".index("w") == 6

  # XXX: do not write:
  #[
  check "a" or "b" == "a"
  check "" or "b" == "b"
  ]#
  # which do not mean what you think from Python 

  check ("a" or "b") == "a"
  check ("" or "b") == "b"

  check fr"{666.0} Hello {42} World {true} ! {1 + 2}" == "666.0 Hello 42 World true ! 3"
  check fr"" == ""
  check fr" " == " "
  check fr"""""" == ""
  check fr""" """ == " "
  check fr"hello {42}" & " world" == "hello 42 world"

  check not "abc".endswith("bc", 0, 2)
  check     "abc".endswith("bc", 0, 3)

  check "abc".endswith(("1", "c"))

  check "123".count("") == 4

test "str.maketrans&translate":
  let self = (1,)  # just a placeholder
  template checkequalnofix(s: typeof(self), res, self: PyStr, args: varargs[untyped]) =
    check self.translate(args) == res
  template assertEqual(s: typeof(self), a, b) =
    check a == b
  
  # copied from CPython/Lib/test/test_str.py StrTest.test_maketrans_translate
  # with a little modification.

  # NOTE: some of the following tests takes the feature of untyped params,
  # parsing dict literal with mixin value of NoneType, str, int

  # these work with plain translate()
  self.checkequalnofix("bbbc", "abababc", PyStr.maketrans {'a': None})
  self.checkequalnofix("iiix", "abababc", 
                      PyStr.maketrans {'a': None, 'b': 'i', 'c': "x"})
  self.checkequalnofix("c", "abababc", 
                      PyStr.maketrans {'a': None, 'b': ""})
  
  self.checkequalnofix("xyyx", "xzx", 
                        PyStr.maketrans {'z': "yy"})

  self.checkequalnofix("a<i>a<i>a<i>c", "abababc", 
                      PyStr.maketrans {"b": "<i>"})
  let tbl = PyStr.maketrans({"a": None, "b": "<i>"})
  self.checkequalnofix("<i><i><i>c", "abababc",  tbl)
  # test alternative way of calling maketrans()
  let tbl2 = PyStr.maketrans("abc", "xyz", "d")
  self.checkequalnofix("xyzzy", "abdcdcbdddd",  tbl2)

  # various tests switching from ASCII to latin1 or the opposite;
  # same length, remove a letter, or replace with a longer string.
  self.assertEqual("[a]".translate(PyStr.maketrans("a", "X")),
                    "[X]")
  self.assertEqual("[a]".translate(PyStr.maketrans({"a": "X"})),
                    "[X]")
  self.assertEqual("[a]".translate(PyStr.maketrans({"a": None})),
                    "[]")
  self.assertEqual("[a]".translate(PyStr.maketrans({"a": "XXX"})),
                    "[XXX]")
  self.assertEqual("[a]".translate(PyStr.maketrans({"a": "\xe9"})),
                    "[\xe9]")
  self.assertEqual("axb".translate(PyStr.maketrans({"a": None, "b": "123"})),
                    "x123")
  self.assertEqual("axb".translate(PyStr.maketrans({"a": None, "b": "\xe9"})),
                    "x\xe9")

  # test non-ASCII (don't take the fast-path)
  self.assertEqual("[a]".translate(PyStr.maketrans({"a": "<\xe9>"})),
                    "[<\xe9>]")
  self.assertEqual("[\xe9]".translate(PyStr.maketrans({"\xe9": "a"})),
                    "[a]")
  self.assertEqual("[\xe9]".translate(PyStr.maketrans({"\xe9": None})),
                    "[]")
  self.assertEqual("[\xe9]".translate(PyStr.maketrans({"\xe9": "123"})),
                    "[123]")
  self.assertEqual("[a\u03b1]".translate(PyStr.maketrans({"a": "<\u20ac>"})),
                    "[<\u20ac>\u03b1]")

  # CPython's test here uses `\xe9`, which is of Extended ASCII,
  # and is in fact not UTF-8, (its UTF-8 binary reperentation is `\xxc3\xa9`)
  # so I use `\u03b1` instead.
