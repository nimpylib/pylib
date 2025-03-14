
# quotation mark of string literal

## desc

Python allows both `'` and `"` as string literal quotation mark;

while Nim only allows `"`. (`'` is for character literal)


## rewrite
```
"'" STR_CONTENT "'" -> "\"" STR_CONTENT_TRANS "\""
```

`STR_CONENT_TRANS` =  `STR_CONTENT`.replace('\'', '"')
