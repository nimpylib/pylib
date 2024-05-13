
# reference source: Modules/posixmodule.c

import std/os

import ./common


proc getcwd*(): PyStr = str getCurrentDir()
proc getcwdb*(): PyBytes = bytes getCurrentDir()
proc chdir*(s: PathLike) = setCurrentDir $s




