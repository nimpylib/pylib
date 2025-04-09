
import std/os
const JS = defined(js)
when JS:
  import ../common
  let pid{.importDenoOrProcess(pid).}: int

proc getpid*(): int =
  when JS: pid else: getCurrentProcessId()

when defined(windows):
  import std/winlean
  
  type
    ULONG = uint32
    ULONG_PTR = ULONG
    NTSTATUS = uint32 ##\
    ## https://learn.microsoft.com/en-us/openspecs/windows_protocols/ms-erref/87fba13e-bf06-450e-83b1-9241dc81e781
    KPRIORITY{.importc, header: "<ks.h>".} = object
      PriorityClass, PrioritySubClass: ULONG
  type
    ProcessBasicInformationFull = object
      ## `_PROCESS_BASIC_INFORMATION`
      ## https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess#process_basic_information
      ExitStatus: NTSTATUS
      PebBaseAddress: pointer  ## `PEB *` in `<winternl.h>`
      AffinityMask: ULONG_PTR
      BasePriority: KPRIORITY
      UniqueProcessId: ULONG_PTR
      InheritedFromUniqueProcessId: ULONG_PTR

    PROCESSINFOCLASS = enum
      ProcessBasicInformation = cint 0

    PNT_QUERY_INFORMATION_PROCESS = proc(handle: Handle, infoClass: PROCESSINFOCLASS, 
        info: pointer, infoLen: ULONG, retLen: ptr ULONG): NTSTATUS {.stdcall.}
    HMODULE = Handle

    FARPROC = pointer  ## XXX: pointer to function in C

  proc NT_SUCCESS(status: NTSTATUS): bool{.importc, nodecl.}

  proc GetModuleHandleA(lpModuleName: cstring): HMODULE {.importc, header: "<libloaderapi.h>", stdcall.} ## \
  ## DO NOT pass result to FreeLibrary,
  ## ref https://learn.microsoft.com/en-us/windows/win32/api/libloaderapi/nf-libloaderapi-getmodulehandlew
  proc GetProcAddress(hModule: HMODULE, lpProcName: cstring): FARPROC {.importc, header: "<libloaderapi.h>", stdcall.}

  var cachedPpid: ULONG = 0
  proc win32_getppid_fast(): uint =
    ## This function returns the process ID of the parent process.
    ## Returns 0 on failure.
    if cachedPpid != 0:
      return cachedPpid

    let ntdll = GetModuleHandleA("ntdll.dll")
    if ntdll == 0:
      return 0

    let pNtQueryInformationProcess = cast[PNT_QUERY_INFORMATION_PROCESS](
        GetProcAddress(ntdll, "NtQueryInformationProcess"))
    ## https://learn.microsoft.com/en-us/windows/win32/api/winternl/nf-winternl-ntqueryinformationprocess
    if pNtQueryInformationProcess.isNil:
      return 0

    var basicInfo: ProcessBasicInformationFull
    let status = pNtQueryInformationProcess(getCurrentProcess(), ProcessBasicInformation, 
        addr basicInfo, sizeof(basicInfo).ULONG, nil)

    if not NT_SUCCESS(status):
      return 0
    # Perform sanity check on the parent process ID we received from NtQueryInformationProcess.
    # The check covers values which exceed the 32-bit range (if running on x64) as well as
    # zero and (ULONG) -1.

    if basicInfo.InheritedFromUniqueProcessId == 0 or 
        basicInfo.InheritedFromUniqueProcessId >= ULONG.high:
      return 0

    cachedPpid = ULONG basicInfo.InheritedFromUniqueProcessId
    return cachedPpid

  type
    PSS_CAPTURE_FLAGS = enum
      PSS_CAPTURE_NONE = cint 0
    PSS_QUERY_INFORMATION_CLASS = enum
      PSS_QUERY_PROCESS_INFORMATION = cint 0
  const
    ERROR_SUCCESS = 0
  {.push header: "<processsnapshot.h>".}
  {.push stdcall.}
  proc PssCaptureSnapshot(process: Handle, flags: PSS_CAPTURE_FLAGS, 
      snapshotFlags: uint32, snapshot: ptr Handle): uint32 {.importc.}
  proc PssQuerySnapshot(snapshot: Handle, infoClass: PSS_QUERY_INFORMATION_CLASS, 
      info: pointer, infoLen: uint32): uint32 {.importc.}
  proc PssFreeSnapshot(process: Handle, snapshot: Handle): uint32 {.importc, discardable.}
  {.pop.}
  type PSS_PROCESS_INFORMATION{.importc.} = object
    ParentProcessId{.importc.}: uint32
  {.pop.}

  proc win32_getppid(): int =
    let pid = win32_getppid_fast()
    if pid != 0:
      return int(pid)
      
    # Fallback to PSS API if fast method fails
    var snapshot: Handle
    let process = getCurrentProcess()
    let error = PssCaptureSnapshot(process, PSS_CAPTURE_NONE, 0, addr snapshot)
    if error != ERROR_SUCCESS:
      return 0
      
    var info: PSS_PROCESS_INFORMATION
    let queryError = PssQuerySnapshot(snapshot, PSS_QUERY_PROCESS_INFORMATION, 
        addr info, uint32(sizeof(info)))
    result = if queryError == ERROR_SUCCESS: int(info.ParentProcessId)
                 else: 0
                 
    PssFreeSnapshot(process, snapshot)
elif defined(js):
  let ppid{.importDenoOrProcess(ppid).}: int
else:
  import std/posix
proc getppid*(): int =
  ## Returns the parent's process id.
  ## If the parent process has already exited, Windows machines will still
  ## return its id; others systems will return the id of the 'init' process (1).
  when defined(windows): win32_getppid()
  elif JS: ppid
  else: int posix.getppid()
