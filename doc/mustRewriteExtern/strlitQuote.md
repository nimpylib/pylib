
# quotation mark of string literal

## desc

Python allows both `'` and `"` as string literal quotation mark;

while Nim only allows `"`. (`'` is for character literal)


## rewrite
```
STRLIT_BEGIN + -> "\"" +
```

