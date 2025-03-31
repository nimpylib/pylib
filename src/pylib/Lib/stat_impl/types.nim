
when defined(windows):
  type Mode = cushort
else:
  from std/posix import Mode
export Mode
