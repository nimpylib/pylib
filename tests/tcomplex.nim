
test "complex":
  let z = complex(3.0, -4.0)
  check z.imag == -4.0
  check $z == "(3-4j)"
  check z.conjugate() == complex(3.0, 4.0)
  check abs(z) == 5.0
