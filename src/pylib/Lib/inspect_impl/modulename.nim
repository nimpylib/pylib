

from std/algorithm import sort
import std/os
from std/strutils import endsWith

const `importlib.machinery.all_suffixes()` = [".nim", ".nims"]

proc getmodulenameImpl*(path: string, res: var string): bool =
    ## get the module name for a given file
    let fname = extractFilename(path)
    # Check for paths that look like an actual module file
    var suffixes: seq[(int, string)]
    for suffix in `importlib.machinery.all_suffixes()`:
      suffixes.add (len(suffix), suffix)
    suffixes.sort() # try longest suffixes first, in case they overlap
    for (neglen, suffix) in suffixes:
        if fname.endsWith(suffix):
            res = fname[0..^neglen]
            return true
    return false
