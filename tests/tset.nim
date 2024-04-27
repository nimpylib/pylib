
test "set":
  def fun():
    s = pyset([2, 3])
    check(len(s.union([1]))==3)
    check(len(s.intersection([1,2,3]))==2)
  fun()  
  def op():
    s = pyset([2, 3])
    # XXX: s.union("1") will cause Nim complain...
    check(len(s | pyset([1]))==3)
    check(len(s & pyset([1,2,3]))==2)
  op()
    
