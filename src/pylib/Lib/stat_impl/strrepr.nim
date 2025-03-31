
import ./[consts, types, isXImpl]

proc filetype(mode: Mode): char =
  if S_ISREG(mode): '-'
  elif S_ISDIR(mode): 'd'
  elif S_ISLNK(mode): 'l'
  elif S_ISBLK(mode): 'b'
  elif S_ISCHR(mode): 'c'
  elif S_ISFIFO(mode): 'p'
  elif S_ISSOCK(mode): 's'
  elif S_ISDOOR(mode): 'D'
  elif S_ISPORT(mode): 'P'
  elif S_ISWHT(mode): 'w'
  else: '?'

proc fileperm[start: static[int]](mode: Mode, buf: var (array[start+9, char]|string)) =
  let mode = int(mode)
  buf[start] = if (mode and S_IRUSR) != 0: 'r' else: '-'
  buf[start+1] = if (mode and S_IWUSR) != 0: 'w' else: '-'
  buf[start+2] = if (mode and S_ISUID) != 0:
             if (mode and S_IXUSR) != 0: 's' else: 'S'
           else:
             if (mode and S_IXUSR) != 0: 'x' else: '-'
  buf[start+3] = if (mode and S_IRGRP) != 0: 'r' else: '-'
  buf[start+4] = if (mode and S_IWGRP) != 0: 'w' else: '-'
  buf[start+5] = if (mode and S_ISGID) != 0:
             if (mode and S_IXGRP) != 0: 's' else: 'S'
           else:
             if (mode and S_IXGRP) != 0: 'x' else: '-'
  buf[start+6] = if (mode and S_IROTH) != 0: 'r' else: '-'
  buf[start+7] = if (mode and S_IWOTH) != 0: 'w' else: '-'
  buf[start+8] = if (mode and S_ISVTX) != 0:
             if (mode and S_IXOTH) != 0: 't' else: 'T'
           else:
             if (mode and S_IXOTH) != 0: 'x' else: '-'

proc filemode*(omode: Mode): string =
  #var buf: array[10, char]
  var buf = newString(10)
  buf[0] = filetype(omode)
  fileperm[1](omode, buf)
  result = buf

proc filemode*(omode: int): string =
  filemode(int_AsMode_t(omode))
