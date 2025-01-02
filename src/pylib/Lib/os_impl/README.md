
`os` as a directory is because:

os and io mutually depends on each other:

- os.fdopen depends on io.open (as io.open has implemented the case where its first argument `file` is int)
- io depends on some os's functions, like `ftruncate`

To handle this circular dependency, os is splited as several modules into this directory.
