
suite "bytes":
  test "getitem":
    def t_getitem():
      byt = b"asd"
      assert byt[1] == ord('s')
    
    t_getitem()

  test "meth":
    def t_splitlines():
      ls = b"asd\r\nfdfg".splitlines()
      assert ls == [b"asd", b"fdfg"]
    t_splitlines()

    let btab = PyBytes.maketrans(b"bc", b"23")

    check b"HbOa".translate(btab, b"a") == b"H2O"

  test "repr":
    check repr(b"\xfe\xff") == "b'\\xfe\\xff'"
    #check repr(b"\xfe\"\xff") == "b'\\xfe\"\\xff'"
    # XXX: b"\xfe\"\xff" in Nim is parsed as `b"\xfe\"` `\xff"` instead of one string lit.
    check repr(b"\xfe'\xff") ==  "b\"\\xfe'\\xff\""
