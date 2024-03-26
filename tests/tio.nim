

test "io & with":
  const fn = "tempfiletest"
  with open(fn, "w") as f:
    let nchar = f.write("c")
    check nchar == 1
  check readFile(fn) == "c"