
type
  ArithmeticError* = object of CatchableError
  ZeroDivisionError* = object of ArithmeticError
