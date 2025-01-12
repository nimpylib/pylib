# Conditional expressions
## desc

`a if cond else b`

invalid AST in Nim.


## rewrite
```
expr1 "if" cond "else" expr2 -> "if" cond ": " expr1 "else: " expr2
```
