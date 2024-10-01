
import ../common
include ./ncommon
export common


when InJs:
  proc unlinkSync(path: cstring){.importNode(fs, unlinkSync).}
  proc unlinkImpl*(p: PathLike) =
    let cs = cstring $p
    catchJsErrAndRaise:
      unlinkSync cs
    #[ XXX: NIM-BUG: if as follows, when JS, 
      Error: internal error: genTypeInfo(tyUserTypeClassInst)
    catchJsErrAndRaise:
      unlinkSync(cstring($p))
    ]#
else:
  when defined(windows):
    template deleteFile(file: untyped): untyped  = deleteFileW(file)
    template setFileAttributes(file, attrs: untyped): untyped =
      setFileAttributesW(file, attrs)

  # from nim-2.1.2/lib/std/private/osfiles.nim `proc tryRemoveFile`
  proc unlinkAux[T](p: PathLike[T],
      winIgnoreRO: static[bool] = false  # Python does not
    ): bool {.noWeirdTarget.} =
    ## Removes the file at `p`.
    ##
    ## If this fails, returns `false`.
    ## This raises `FileNotFoundError`
    ## if the file never existed.
    ##
    ## On Windows, ignores the read-only attribute.
    ##
    let file = $p
    when defined(windows):
      let f = newWideCString(file)
      if deleteFile(f) != 0:  ## returns TRUE
        return true
      when winIgnoreRO:
        let err = getLastError()
        if err == ERROR_ACCESS_DENIED and
            setFileAttributes(f, FILE_ATTRIBUTE_NORMAL) != 0 and
            deleteFile(f) != 0:
          return true # success
    else:
      if unlink(file) == 0'i32: return true  # success
  proc unlinkImpl*(p: PathLike) =
    if not unlinkAux(p):
      p.raiseExcWithPath()