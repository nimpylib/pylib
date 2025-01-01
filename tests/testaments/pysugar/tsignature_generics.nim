discard """
  action: "compile"
"""
import pylib/pysugar
when PySignatureSupportGenerics:  # pysince 3.13
  # "generics in func signature":
  def f2[A, B](a: A, b: B) -> A:
    # python cannot do:
    return a + A(b)

  # "generics in class's methods":

  class O:
    @staticmethod
    def f2[A, B](a: A, b: B) -> A:
      # python cannot do:
      return a - A(b)
  class X[T]:
    x: T
    def init(self, x: T): self.x = x


  class C[T]:
    def init[B](self, x: T, y: B) :
      discard

  static:
    assert f2(1.0, 1) == 2.0
    assert O.f2(int(1), float(1.0)) == 0
