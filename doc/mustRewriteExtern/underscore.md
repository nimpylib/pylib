# underscore in identifier

## desc

In Nim, identifiers are not allowed to start or end with `_`, nor contain `__`.

Here we recommend to replace `__` with `dunder` and `_` with `sunder`.


## rewrite
```
"_" identifier -> "sunder_" identifier
identifier "_" -> identifier "_sunder"
"__" identifier -> "dunder_" identifier
identifier "__" -> identifier "_dunder"
```
