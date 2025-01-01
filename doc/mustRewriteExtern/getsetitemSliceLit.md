# slice literal in getitem,setitem

## desc

For Python:

<https://docs.python.org/3/library/stdtypes.html#common-sequence-operations>


> 4. The slice of *s* from *i* to *j* is defined as the sequence of items with 
index k such that *i <= k < j*. If *i* or *j* is greater than `len(s)`, use `len(s)`.
If *i* is omitted or `None`, use `0`. If *j* is omitted or `None`, use `len(s)`.
If *i* is greater than or equal to *j*, the slice is empty.


Only `ls[a:b]` is supported in nimpylib, as it's the only one that is a valid AST in Nim.

Either of slice literal with step nor slice omitting any argument are supported.

## rewrite
```
ls "[:" b "]" -> ls "[0:" b "]"
ls "[" a ":]" -> ls "[" a ":len(" ls ")]"
```

```
A ::= if a then a else 0
B ::= if b then b else "len(" ls ")"
STEP ::= if step then step else "1"
ls "[" a? ":" b? ":" step? "]" -> ls "[slice(" A ", " B ", " STEP ")]"
```
