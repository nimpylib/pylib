
As Nim's `std/encodings` currently (as of 2.2.1) lacks `errors`-handler,
you cannot control how encoding error is handled as freely as in Python.

And such a patch is hard to just as an extension around Nim's `std/encodings`,
so a copy is made here:

Copied from Nim's `std/encodings`, when Nim's version is 2.2.1 and:

```shell
~/.../src/Nim $ git log -1 --oneline
b534f34e9 adds noise to important_packages (#24352)
~/.../src/Nim $ git log -1 --oneline -- lib/pure/encodings.nim
c23d6a3cb Update encodings.nim, fix `open` with bad arg raising no `EncodingError` (#23481)
```
