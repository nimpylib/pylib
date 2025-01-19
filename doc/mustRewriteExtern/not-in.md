# not in
## desc
`a not in b` in Python is often written as `a not_in b` in Nim

And though standalone `a not in b is invalid Nim AST, puting it in either assignment statement or if clause fails the Nim AST parser. (tested via `dumpTree` of `std/macros`)

## rewrite
```
a "not" "in" b -> "not" "(" a "in" b ")"
```

