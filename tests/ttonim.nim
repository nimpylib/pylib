test "tonim macro":
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

  check add(5, 3) == 8
  check subtract(6, 3) == 3
  check multiply(5, 7) == 35
  check divide(35, 7) == 5
  check default_arg(0) == "hellohellohellohellohello"

