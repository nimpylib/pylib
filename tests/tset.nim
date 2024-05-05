
test "set":
  def t_shallow():
    s1 = set([1,2,3])
    s2 = s1
    s2.pop()
    check(len(s1)==2)
  t_shallow()
  def fun():
    s = pyset([2, 3])
    check(len(s.union([1]))==3)
    check(len(s.intersection(@[1,2,3]))==2)
  fun()  
  def op():
    s = pyset([2, 3])
    # XXX: s.union("1") will cause Nim complain...
    check(len(s | pyset([1]))==3)
    check(len(s & pyset([1,2,3]))==2)
  op()

  def lit():
    s = pysetLit({1,2,3})
    check(len(s) == 3)
  lit()
    
