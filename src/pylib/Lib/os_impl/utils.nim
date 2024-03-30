
# reference source: Modules/posixmodule.c

import std/os

import ./common


proc getcwd*(): string = getCurrentDir()
proc chdir*(s: PathLike) = setCurrentDir fspath s

proc mkdir*(d: PathLike) = createDir fspath d
proc rmdir*(d: PathLike) = removeDir fspath d



