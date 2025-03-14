# condition expression

## desc

Python supports what's called `triple operation` in C as `ifExpr if cond else elseExpr`

## rewrite
```
ifExpr "if" cond "else" elseExpr -> "if" cond ":" ifExpr "else" ":" elseExpr
```



