import pylib

print( f"{9.0} Hello {42} World {1 + 2}" ) # Python-like string interpolation
let python_like_range = xrange(0, -10, -2) # range() is named xrange() like Python2
print(list(python_like_range)) # @[0, -2, -4, -6, -8]

for i in xrange(10):
  # 0 1 2 3 4 5 6 7 8 9
  print(i, endl=" ")
print("done!")

# Python-like variable unpacking
let data = list(xrange(3, 15, 2))
data.unpack(first, second, *rest, last)
assert (first + second + last) == (3 + 5 + 13)
assert rest == @[7, 9, 11]

if (a := 6) > 5:
  assert a == 6

if (b := 42.0) > 5.0:
  assert b == 42.0

if (c := "hello") == "hello":
  assert c == "hello"

print(capwords("hello world capitalized")) # "Hello World Capitalized"
print("a".center(9)) # "         a         "

print("" or "b") # "b"
print("a" or "b") # "a"

print(not "") # true

print("Hello,", input("What is your name? "), endl="\n~\n")

pass # do nothing
pass str("This is a string.") # discard the string

let integer_bytes = 2_313_354_324
var bite, kilo, mega, giga, tera, peta, exa, zetta, yotta: int
(kilo, bite) = divmod(integer_bytes, 1_024)
(mega, kilo) = divmod(kilo, 1_024)
(giga, mega) = divmod(mega, 1_024)
(tera, giga) = divmod(giga, 1_024)
(peta, tera) = divmod(tera, 1_024)
(exa, peta)  = divmod(peta, 1_024)
(zetta, exa) = divmod(exa,  1_024)
(yotta, zetta) = divmod(zetta, 1_024)

let arg = "hello"
let anon = lambda: arg + " world"
assert anon() == "hello world"

print(json_loads("""{"key": "value"}""")) # {"key":"value"}

print(sys.platform) # "linux"

print(platform.processor) # "amd64"

var truty: bool
truty = all([True, True, False])
print(truty) # false

truty = any([True, True, False])
print(truty) # true

from std/os import sleep

timeit(100):  # Python-like timeit.timeit("code_to_benchmark", number=int)
  sleep(9)    # Repeats this code 100 times. Output is very informative.

# 2020-06-17T21:59:09+03:00 TimeIt: 100 Repetitions on 927 milliseconds, 704 microseconds, and 816 nanoseconds, CPU Time 0.0007382400000000003.

# Support for Python-like with statements
# All objects are closed at the end of the with statement
with open("some_file.txt", 'w') as file:
  file.write_line("hello world!")

with open("some_file.txt", 'r') as file:
  while not end_of_file(file):
    print(file.read_line())

with NamedTemporaryFile() as file:
  file.write_line("test!")

with TemporaryDirectory() as name:
  print(name)

type Example = ref object
  start: int
  stop: int
  step: int

class Example(object):  # Mimic simple Python "classes".
  """Example class with Python-ish Nim syntax!."""

  def init(self, start, stop, step=1):
    self.start = start
    self.stop = stop
    self.step = step

  def stopit(self, argument):
    """Example function with Python-ish Nim syntax."""
    self.stop = argument
    return self.stop

let e = newExample(5, 3)
print(e.stopit(5))
