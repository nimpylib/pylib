

import std/enumutils


type Errno*{.pure.} = enum
  E_SUCCESS = "success"  ## inner. unstable.
  E2BIG = "Argument list too long"
  EACCES = "Permission denied"
  EADDRINUSE = "Address already in use"
  EADDRNOTAVAIL = "Cannot assign requested address"
  EADV = "Advertise error"
  EAFNOSUPPORT = "Address family not supported by protocol"
  EAGAIN = "Resource temporarily unavailable"
  EALREADY = "Operation already in progress"
  EBADE = "Invalid exchange"
  EBADF = "Bad file descriptor"
  EBADFD = "File descriptor in bad state"
  EBADMSG = "Bad message"
  EBADR = "Invalid request descriptor"
  EBADRQC = "Invalid request code"
  EBADSLT = "Invalid slot"
  EBFONT = "Bad font file format"
  EBUSY = "Device or resource busy"
  ECANCELED = "Operation canceled"
  ECHILD = "No child processes"
  ECHRNG = "Channel number out of range"
  ECOMM = "Communication error on send"
  ECONNABORTED = "Software caused connection abort"
  ECONNREFUSED = "Connection refused"
  ECONNRESET = "Connection reset by peer"
  EDEADLK = "Resource deadlock avoided"
  EDEADLOCK = "Resource deadlock avoided"
  EDESTADDRREQ = "Destination address required"
  EDOM = "Numerical argument out of domain"
  EDOTDOT = "RFS specific error"
  EDQUOT = "Disk quota exceeded"
  EEXIST = "File exists"
  EFAULT = "Bad address"
  EFBIG = "File too large"
  EHOSTDOWN = "Host is down"
  EHOSTUNREACH = "No route to host"
  EIDRM = "Identifier removed"
  EILSEQ = "Invalid or incomplete multibyte or wide character"
  EINPROGRESS = "Operation now in progress"
  EINTR = "Interrupted system call"
  EINVAL = "Invalid argument"
  EIO = "Input/output error"
  EISCONN = "Transport endpoint is already connected"
  EISDIR = "Is a directory"
  EISNAM = "Is a named type file"
  EKEYEXPIRED = "Key has expired"
  EKEYREJECTED = "Key was rejected by service"
  EKEYREVOKED = "Key has been revoked"
  EL2HLT = "Level 2 halted"
  EL2NSYNC = "Level 2 not synchronized"
  EL3HLT = "Level 3 halted"
  EL3RST = "Level 3 reset"
  ELIBACC = "Can not access a needed shared library"
  ELIBBAD = "Accessing a corrupted shared library"
  ELIBEXEC = "Cannot exec a shared library directly"
  ELIBMAX = "Attempting to link in too many shared libraries"
  ELIBSCN = ".lib section in a.out corrupted"
  ELNRNG = "Link number out of range"
  ELOOP = "Too many levels of symbolic links"
  EMEDIUMTYPE = "Wrong medium type"
  EMFILE = "Too many open files"
  EMLINK = "Too many links"
  EMSGSIZE = "Message too long"
  EMULTIHOP = "Multihop attempted"
  ENAMETOOLONG = "File name too long"
  ENAVAIL = "No XENIX semaphores available"
  ENETDOWN = "Network is down"
  ENETRESET = "Network dropped connection on reset"
  ENETUNREACH = "Network is unreachable"
  ENFILE = "Too many open files in system"
  ENOANO = "No anode"
  ENOBUFS = "No buffer space available"
  ENOCSI = "No CSI structure available"
  ENODATA = "No data available"
  ENODEV = "No such device"
  ENOENT = "No such file or directory"
  ENOEXEC = "Exec format error"
  ENOKEY = "Required key not available"
  ENOLCK = "No locks available"
  ENOLINK = "Link has been severed"
  ENOMEDIUM = "No medium found"
  ENOMEM = "Cannot allocate memory"
  ENOMSG = "No message of desired type"
  ENONET = "Machine is not on the network"
  ENOPKG = "Package not installed"
  ENOPROTOOPT = "Protocol not available"
  ENOSPC = "No space left on device"
  ENOSR = "Out of streams resources"
  ENOSTR = "Device not a stream"
  ENOSYS = "Function not implemented"
  ENOTBLK = "Block device required"
  ENOTCONN = "Transport endpoint is not connected"
  ENOTDIR = "Not a directory"
  ENOTEMPTY = "Directory not empty"
  ENOTNAM = "Not a XENIX named type file"
  ENOTRECOVERABLE = "State not recoverable"
  ENOTSOCK = "Socket operation on non-socket"
  ENOTSUP = "Operation not supported"
  ENOTTY = "Inappropriate ioctl for device"
  ENOTUNIQ = "Name not unique on network"
  ENXIO = "No such device or address"
  EOPNOTSUPP = "Operation not supported"
  EOVERFLOW = "Value too large for defined data type"
  EOWNERDEAD = "Owner died"
  EPERM = "Operation not permitted"
  EPFNOSUPPORT = "Protocol family not supported"
  EPIPE = "Broken pipe"
  EPROTO = "Protocol error"
  EPROTONOSUPPORT = "Protocol not supported"
  EPROTOTYPE = "Protocol wrong type for socket"
  ERANGE = "Numerical result out of range"
  EREMCHG = "Remote address changed"
  EREMOTE = "Object is remote"
  EREMOTEIO = "Remote I/O error"
  ERESTART = "Interrupted system call should be restarted"
  ERFKILL = "Operation not possible due to RF-kill"
  EROFS = "Read-only file system"
  ESHUTDOWN = "Cannot send after transport endpoint shutdown"
  ESOCKTNOSUPPORT = "Socket type not supported"
  ESPIPE = "Illegal seek"
  ESRCH = "No such process"
  ESRMNT = "Srmount error"
  ESTALE = "Stale file handle"
  ESTRPIPE = "Streams pipe error"
  ETIME = "Timer expired"
  ETIMEDOUT = "Connection timed out"
  ETOOMANYREFS = "Too many references: cannot splice"
  ETXTBSY = "Text file busy"
  EUCLEAN = "Structure needs cleaning"
  EUNATCH = "Protocol driver not attached"
  EUSERS = "Too many users"
  EWOULDBLOCK = "Resource temporarily unavailable"
  EXDEV = "Invalid cross-device link"
  EXFULL = "Exchange full"

static: assert Errno is Ordinal
const ErrnoCount* = 1 + ord(high Errno) - 1  # exclude E_SUCCESS

func strerror*(e: Errno): string = system.`$` e

func `$`*(e: Errno): string = symbolName e


