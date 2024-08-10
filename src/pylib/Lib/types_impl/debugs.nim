
##[
  .. note:: almost all functionalities here is only available in debug mode,
    e.g. not when `-d:release`
]##


#[
# dev-manual

## types
StackTraceEntry = object
  procname*: cstring         ## Name of the proc that is currently executing.
  line*: int                 ## Line number of the proc that is currently executing.
  filename*: cstring         ## Filename of the proc that is currently executing.
  ...

PFrame = ptr TFrame
TFrame {.importc, nodecl, final.} = object
  prev*: PFrame              ## Previous frame; used for chaining the call stack.
  procname*: cstring         ## Name of the proc that is currently executing.
  line*: int                 ## Line number of the proc that is currently executing.
  filename*: cstring         ## Filename of the proc that is currently executing.
  len*: int16                ## Length of the inspectable slots.
  calldepth*: int16          ## Used for max call depth checking.

## procs

proc getStackTraceEntries([e: ref Exception]): seq[StackTraceEntry]
proc getFrame(): PFrame

]#

type
  FrameType*{.acyclic.} = ref object
    # RO
    f_back: FrameType
    #[f_code*: 
    f_locals*: 
    f_globals*: 
    f_builtins*: ]#
    f_lasti*: int  ## Always 0 here, see `TracebackType`_ for details

    # RW
    f_lineno*: int

  TracebackType*{.acyclic.} = ref object
    # RO
    tb_frame: FrameType
    tb_lineno: int
    tb_lasti*: int  ## .. note:: as Nim is a compile-language,
                    ##   no opcode here, so this attr is always 0

    # RW
    tb_next*: TracebackType

func f_back*(f: FrameType): FrameType = self.f_back


func tb_frame*(tb: TracebackType): FrameType = self.tb_frame
func tb_lineno*(tb: TracebackType): FrameType = self.tb_lineno


proc newPyFrame*(f: PFrame = getFrame()): FrameType =
  FrameType(
    f_back: f.prev,
    f_lineno: f.line
  )
proc newPyFrame*(f: StackTraceEntry, f_back: FrameType = nil, f_lasti=0): FrameType =
  FrameType(
    f_back: f_back,
    f_lineno: f.line,
    f_lasti: f_lasti,
  )

proc newPyTraceback*(st: StackTraceEntry, f: PFrame, tb_next: TracebackType = nil): TracebackType =
  let pyf = newPyFrame f
  TracebackType(
    tb_frame: pyf,
    tb_lineno: f.line,
    tb_lasti: pyf.f_lasti,
    tb_next: tb_next
  )

proc newPyTraceback*(st: seq[StackTraceEntry] = getStackTraceEntries()
): TracebackType =
  ## may used to implement traceback.print_*
  for i in countdown(st.high, 0):
    result = newPyTraceback(st[i], newPyFrame(st),
      tb_next=result)

proc `traceback.print_stack`*(f: FrameType = newPyFrame()
     file=stderr) =
  let st = getStackTraceEntries()
  for i in countdown(st.high, max(0, st.high-limit)):
    let s = st[i]
    file.write "File $#, line $#, in $#\n".format(
      s.filename, f.line, f.procname)


func newPyTraceback*(tb_next: TracebackType,
    tb_frame: FrameType, tb_lasti, tb_lineno: int): TracebackType =
  TracebackType(
    tb_frame: tb_frame,
    tb_lineno: tb_lineno,
    tb_lasti: tb_lasti,
    tb_next: tb_next,
  )

#[
# Graph

## Python
f1          f2
     <-     .f_back
^
|
.tb_frame
tb1         tb2
.tb_next ->

## Nim

getStackTraceEntries([e: ref Exception]) -> [GlobalScope, ..., PreviousStack, CurrentStack]

]#

proc getLastTraceback*()
