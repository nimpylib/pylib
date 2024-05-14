
import ../common
include ./ncommon
export common

when defined(windows) and not weirdTarget:
  template deleteFile(file: untyped): untyped  = deleteFileW(file)
  template setFileAttributes(file, attrs: untyped): untyped =
    setFileAttributesW(file, attrs)

# from nim-2.1.2/lib/std/private/osfiles.nim `proc tryRemoveFile`
proc unlinkImpl*[T](p: PathLike[T],
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
    let err = getLastError()
    if err == ERROR_FILE_NOT_FOUND or err == ERROR_PATH_NOT_FOUND:
      p.raiseFileNotFoundError err.OSErrorCode
    when winIgnoreRO:
      if err == ERROR_ACCESS_DENIED and
          setFileAttributes(f, FILE_ATTRIBUTE_NORMAL) != 0 and
          deleteFile(f) != 0:
        return true # success
  else:
    if unlink(file) == 0'i32: return true  # success
    if errno == ENOENT:
      p.raiseFileNotFoundError(errno.OSErrorCode)
