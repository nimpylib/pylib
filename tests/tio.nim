

test "io & with":
  const fn = "tempfiletest"
  with open(fn, "w") as f:
    let nchar = f.write("c")
    check nchar == 1
  check readFile(fn) == "c"
  block:
    var f = open(fn, "w+b")
    f.write(br"123")
    f.seek(0)
    assert f.read() == br"123"
    f.close()
