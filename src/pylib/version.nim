
const sep = '.'
template asVersion*(v: tuple): string = asVersion(v[0], v[1], v[2])
template asVersion*(major, minor, patch: int): string =
  $major & sep & $minor & sep & $patch

const
  Major* = 0
  Minor* = 9
  Patch* = 0
  Version* = asVersion(Major, Minor, Patch)

  ReleaseLevel* = "alpha"
  Serial* = 0

  PyMajor* = 3
  PyMinor* = 10
  PyPatch* = 3
  PyReleaseLevel* = "final"
  PySerial* = 0

