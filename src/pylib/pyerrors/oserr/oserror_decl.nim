
type PyOSError* = object of system.OSError
  ## Python-compatible OSError
  errno*: cint
  strerror*,
    filename*,
    filename2*: string
  when defined(windows):
    winerror*: cint ## Windows-specific error code
  characters_written*: int

#type OSError* = PyOSError
