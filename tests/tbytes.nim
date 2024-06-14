
test "bytes":
  def t_getitem():
    byt = b"asd"
    assert byt[1] == ord('s')
  
  t_getitem()

test "bytes meth":
  def t_splitlines():
    ls = b"asd\r\nfdfg".splitlines()
    assert ls == [b"asd", b"fdfg"]
  t_splitlines()

  let btab = PyBytes.maketrans(b"bc", b"23")

  check b"HbOa".translate(btab, b"a") == b"H2O"
