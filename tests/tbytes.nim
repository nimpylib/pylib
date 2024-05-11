
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
