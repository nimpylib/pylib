
# reference source: Modules/posixmodule.c

import std/os

import ./common


proc getcwd*(): string = getCurrentDir()
proc chdir*(s: PathLike) = setCurrentDir $s

proc mkdir*(d: PathLike) = createDir $d
proc rmdir*(d: PathLike) = removeDir $d



