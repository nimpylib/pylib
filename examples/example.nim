import pylib
include pylib/range  # It's neccessary to include range module separately
let data = range(0, -10, -2)
echo data # @[0, -2, -4, -6, -8]
for i in range(10):
  print(i, endl = " ")  # 0 1 2 3 4 5 6 7 8 9

print("Hello,", input("What is your name? "), endl="\n~~~\n")