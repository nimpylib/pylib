
import ./stmt/class
export class.new, class.init_subclass
import ./parserWithCfg

macro classAux(obj, body: untyped, topLevel: static[bool]): untyped = 
  ## wrapper of `classImpl proc<./stmt/tonim.html>`_
  runnableExamples:
    class O:
      "doc"
      a: int
      b = 2
      c: int = 1
      def f(self): return self.b
    assert O().f() == 2
    
    class O1(O):
      a1 = -1
      def f(self): return self.a1
    assert O1().a == 0
    assert O(O1()).f() == -1

    # will error: class OO(O1, O): aaa = 1

    class C:
      def f(self, b: float) -> int: return 1+int(b)
    assert C().f(2) == 3

    class CC(C):
      def f(self, b: float):
        return super().f(b)
    assert CC().f(2) == 3
  var parser = parserWithDefCfg()
  parser.classImpl(obj, body, topLevel)

template class*(obj, body) =
  bind classAux
  classAux(obj, body,
    instantiationInfo().column == 0
    # cannot handle `when`
  )

