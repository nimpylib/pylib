
import ./stmt/tonim

macro tonim*(body): untyped =
  runnableExamples:
    var GLOBAL = 1
    tonim:
      num = 8
      global GLOBAL
      GLOBAL = 3
      doAssertRaises ValueError: raise ValueError
      doAssertRaises ValueError: raise ValueError()
      doAssertRaises ValueError: raise ValueError("msg")
      doAssertRaises ValueError:
        # Nim-favor is remained.
        raise newException(ValueError,"msg")
    assert GLOBAL == 3
  result = parsePyBody(body)

#[
import ../pylib

tonim:
  def add(x, y):
    return x + y

  def subtract(x, y):
    return x - y

  def multiply(x, y):
    return x * y

  def divide(x, y):
    return x / y

  def default_arg(x, y = 5):
    return "hello" * y

  my_list = ["apples", "bananas"]
  print(my_list)

  # Python Program to calculate the square root

  # Note: change this value for a different result
  num = 8

  # To take the input from the user
  #num = float(input('Enter a number: '))

  num_sqrt = num ** 0.5
  print(num_sqrt)

  print add(5, 3)
  print add(5.0, 3.0)
  print subtract(6, 3)
  print multiply(5, 7)
  print divide(35, 7)
  print default_arg(0)

]#