
# triple string literal

## desc

For Nim:

<https://nim-lang.org/docs/manual.html#lexical-analysis-triple-quoted-string-literals>

> For convenience, when the opening `"""` is followed by a newline (there may be whitespace between the opening `"""` and the newline), the newline (and the preceding whitespace) is not included in the string.


## rewrite

```
TRIPLE_STRLIT_BEGIN "\p" -> "\"\"\"\\n"
```

