import pylib

let data = xrange(0, -10, -2)
echo data # xrange(0, -10, -2)
echo list(data) #  @[0, -2, -4, -6, -8]

for i in xrange(10):
  print(i, endl = " ")  # 0 1 2 3 4 5 6 7 8 9

print("\n~~~")
print("Hello,", input("What is your name? "), endl="\n~~~\n")
