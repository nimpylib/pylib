
const sep = '.'
template asVersion*(v: tuple): string = asVersion(v[0], v[1], v[2])
template asVersion*(major, minor, patch: int): string =
  $major & sep & $minor & sep & $patch

const
  Major* = 0
  Minor* = 9
  Patch* = 1
  Version* = asVersion(Major, Minor, Patch)

  ReleaseLevel* = "alpha"
  Serial* = 0

  PyMajor*{.intdefine.} = 3
  PyMinor*{.intdefine.} = 10
  PyPatch*{.intdefine.} = 3
  PyReleaseLevel* = "final"
  PySerial* = 0

template pysince*(major, minor: int, def){.dirty.} =
  when (PyMajor, PyMinor) >= (major, minor):
    def
