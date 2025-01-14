# `end` keyword

## desc
In Python, `end` may be used in `print` function (or as a identifier).

However, in Nim, `end` is a keyword (though unused).

So such a statement like `print(1, end="")` is an invalid AST of Nim.

As a workaround, either `endl` or **\`end\`** can be used instead.

And the latter is recommanded (supported after v0.9.5)
as it never introduces name collision thus being simpler when rewritting.

## rewrite
```
"end" -> "`end`"
```
