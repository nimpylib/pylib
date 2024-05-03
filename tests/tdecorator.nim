
test "decorator":
  class O:
    @staticmethod
    def sm():
      return 1
    @classmethod
    def cm(cls):
      check(cls == O)
      return 2
  
  check(O.sm()==1)
  check(O.cm()==2)
