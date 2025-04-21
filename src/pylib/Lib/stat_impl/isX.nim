
import ./isXImpl
import ./[consts, types]

template makeSIsFuncTemplate(name: untyped) {.dirty.} =
  export isXImpl.`S_IS name`
  proc `S_IS name`*(omode: int): bool =
    `S_IS name` int_AsMode_t(omode)

# Generate S_IS* functions
makeSIsFuncTemplate(DIR)
makeSIsFuncTemplate(CHR)
makeSIsFuncTemplate(BLK)
makeSIsFuncTemplate(REG)
makeSIsFuncTemplate(FIFO)
makeSIsFuncTemplate(LNK)
makeSIsFuncTemplate(SOCK)
makeSIsFuncTemplate(DOOR)
makeSIsFuncTemplate(PORT)
makeSIsFuncTemplate(WHT)


proc S_IMODE*(omode: int): int =
  let mode = int_AsMode_t(omode)
  int(mode and S_IMODE_val)

# const stat_S_IMODE_doc = "Return the portion of the file's mode that can be set by os.chmod()."

proc S_IFMT*(omode: Mode): int =
  int(omode and Mode S_IFMT_val)

proc S_IFMT*(omode: int): int =
  S_IFMT(int_AsMode_t(omode))

# const stat_S_IFMT_doc = "Return the portion of the file's mode that describes the file type."
