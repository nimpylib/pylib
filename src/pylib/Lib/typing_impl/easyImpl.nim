
type
  Final*[T] = T
  Literal* = auto  ##[
   Its `__class_getitem__` (e.g. `Literal[1, 2]`) is (and only is) supported within `def` or `class` via
   `rewriteDeclXxx` in `pysugar/stmt/decl.nim`

   .. note::
    bare `Literal` (without any generic type) is disallowed in mypy,
    here we support it as we use it to refer to `const`
  ]##
