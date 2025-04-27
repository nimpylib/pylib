

import ./defines
import ../../pyconfig/util


template genIntImpl(name, cname; defval: int, header = SYS_STAT_H) =
  const name = from_c_int(cname, defval, header)

template genInt(name; defval: int, header = SYS_STAT_H) =
  genIntImpl(name, name, defval, header)
  export name

when DW:
  genInt FILE_ATTRIBUTE_INTEGRITY_STREAM, 0x8000, WINNT_H
  genInt FILE_ATTRIBUTE_NO_SCRUB_DATA, 0x20000, WINNT_H
  genInt IO_REPARSE_TAG_APPEXECLINK, 0x8000001B, WINNT_H

const S_IMODE_val*{.intdefine: "S_IMODE".} = 0o7777

#[S_IFXXX constants (file types)

Only the names are defined by POSIX but not their value. All common file
types seems to have the same numeric value on all platforms, though.

pyport.h guarantees S_IFMT, S_IFDIR, S_IFCHR, S_IFREG and S_IFLNK]#

# File type constants

genIntImpl S_IFMT_val, S_IFMT, 0o170000  # File type mask
export S_IFMT_val
genInt S_IFDIR, 0o040000 # Directory
genInt S_IFCHR, 0o020000 # Character device
genInt S_IFBLK, 0o060000 # Block device
genInt S_IFREG, 0o100000 # Regular file
genInt S_IFIFO, 0o010000 # FIFO
genInt S_IFLNK, 0o120000 # Symbolic link
genInt S_IFSOCK, 0o140000 # Socket
genInt S_IFDOOR, 0 # Door
genInt S_IFPORT, 0 # Event port
genInt S_IFWHT, 0 # Whiteout


# S_I* file permission
# The permission bits value are defined by POSIX standards.

# Permission bits
genInt S_ISUID, 0o4000 # Set UID
genInt S_ISGID, 0o2000 # Set GID
genInt S_ENFMT, S_ISGID # File locking enforcement
genInt S_ISVTX, 0o1000 # Sticky bit
genInt S_IREAD, 0o0400 # Read by owner
genInt S_IWRITE, 0o0200 # Write by owner
genInt S_IEXEC, 0o0100 # Execute by owner
genInt S_IRWXU, 0o0700 # Owner mask
genInt S_IRUSR, 0o0400 # Read by owner
genInt S_IWUSR, 0o0200 # Write by owner
genInt S_IXUSR, 0o0100 # Execute by owner
genInt S_IRWXG, 0o0070 # Group mask
genInt S_IRGRP, 0o0040 # Read by group
genInt S_IWGRP, 0o0020 # Write by group
genInt S_IXGRP, 0o0010 # Execute by group
genInt S_IRWXO, 0o0007 # Others mask
genInt S_IROTH, 0o0004 # Read by others
genInt S_IWOTH, 0o0002 # Write by others
genInt S_IXOTH, 0o0001 # Execute by others

# File flags
genInt UF_SETTABLE, 0x0000ffff
genInt UF_NODUMP, 0x00000001
genInt UF_IMMUTABLE, 0x00000002
genInt UF_APPEND, 0x00000004
genInt UF_OPAQUE, 0x00000008
genInt UF_NOUNLINK, 0x00000010
genInt UF_COMPRESSED, 0x00000020
genInt UF_TRACKED, 0x00000040
genInt UF_DATAVAULT, 0x00000080
genInt UF_HIDDEN, 0x00008000
when not APPLE:
  genInt SF_SETTABLE, 0xffff0000
genInt SF_ARCHIVED, 0x00010000
genInt SF_IMMUTABLE, 0x00020000
genInt SF_APPEND, 0x00040000
genInt SF_NOUNLINK, 0x00100000
genInt SF_SNAPSHOT, 0x00200000
genInt SF_FIRMLINK, 0x00800000
genInt SF_DATALESS, 0x40000000

when APPLE:
  #[On older macOS versions the definition of SF_SUPPORTED is different
from that on newer versions.
    *
Provide a consistent experience by redefining.
    *
None of bit bits set in the actual SF_SUPPORTED but not in this
definition are defined on these versions of macOS.]#
  const invSup = int.high
  genIntImpl tSF_SUPPORTED, SF_SUPPORTED, invSup
  when tSF_SUPPORTED != invSup:  # :c:`defined(SF_SUPPORTED)`
    const SF_SUPPORTED* = tSF_SUPPORTED
    template addIntIfDefined(name) =
      genIntImpl name, name, invSup
      when name != invSup:
        export name
    addIntIfDefined SF_SETTABLE
    addIntIfDefined SF_SYNTHETIC
  else:
    const
      SF_SUPPORTED* = 0x009f0000
      SF_SETTABLE* = 0x3fff0000
      SF_SYNTHETIC* = 0xc0000000


#const stat_filemode_doc = "Convert a file's mode to a string of the form '-rwxrwxrwx'"

when DW:
  import ../os_impl/util/mywinlean
  template exp(name) =
    export name
  template impExp(name) =
    let name*{.importc: astToStr(name), header: WINNT_H.}: DWORD
  # Add Windows-specific constants
  #  the following commented out constants are defined above.
  impExp(FILE_ATTRIBUTE_ARCHIVE)
  impExp(FILE_ATTRIBUTE_COMPRESSED)
  impExp(FILE_ATTRIBUTE_DEVICE)
  exp(FILE_ATTRIBUTE_DIRECTORY)
  impExp(FILE_ATTRIBUTE_ENCRYPTED)
  impExp(FILE_ATTRIBUTE_HIDDEN)
  #impExp(FILE_ATTRIBUTE_INTEGRITY_STREAM)
  impExp(FILE_ATTRIBUTE_NORMAL)
  impExp(FILE_ATTRIBUTE_NOT_CONTENT_INDEXED)
  #impExp(FILE_ATTRIBUTE_NO_SCRUB_DATA)
  impExp(FILE_ATTRIBUTE_OFFLINE)
  exp(FILE_ATTRIBUTE_READONLY)
  exp(FILE_ATTRIBUTE_REPARSE_POINT)
  impExp(FILE_ATTRIBUTE_SPARSE_FILE)
  impExp(FILE_ATTRIBUTE_SYSTEM)
  impExp(FILE_ATTRIBUTE_TEMPORARY)
  impExp(FILE_ATTRIBUTE_VIRTUAL)

  exp(IO_REPARSE_TAG_SYMLINK)
  exp(IO_REPARSE_TAG_MOUNT_POINT)
  #impExp(IO_REPARSE_TAG_APPEXECLINK)
