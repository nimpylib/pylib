{.used.}
import ./utils
addPatch((2,1,1), defined(windows)):
  ## introduced in nim-lang/Nim#23456
  # patch for system/io.nim or std/syncio.nim,
  # see https://github.com/nim-lang/Nim/pull/23456
  when defined(nimPreviewSlimSystem):
    import std/syncio
  const
    NoInheritFlag =
      # Platform specific flag for creating a File without inheritance.
      when not defined(nimInheritHandles):
        when defined(windows): ""
        elif defined(linux) or defined(bsd): "e"
        else: ""
      else: ""
    FormatOpen: array[FileMode, cstring] = [
      cstring("rb" & NoInheritFlag), "wb" & NoInheritFlag, "w+b" & NoInheritFlag,
      "r+b" & NoInheritFlag, "ab" & NoInheritFlag
    ]
  when defined(windows):
    proc getOsfhandle(fd: cint): int {.
      importc: "_get_osfhandle", header: "<io.h>".}
    proc c_fdopen(filehandle: cint, mode: cstring): File {.
      importc: "_fdopen", header: "<stdio.h>".}
  else:
    proc c_fdopen(filehandle: cint, mode: cstring): File {.
      importc: "fdopen", header: "<stdio.h>".}
  proc open*(f: var File, filehandle: FileHandle,
            mode: FileMode = fmRead): bool {.tags: [], raises: [].} =
    when not defined(nimInheritHandles) and declared(setInheritable):
      let oshandle = when defined(windows): FileHandle getOsfhandle(filehandle)
                    else: filehandle
      if not setInheritable(oshandle, false):
        return false
    let fop = FormatOpen[mode]
    f = c_fdopen(filehandle, fop)
    result = f != nil
