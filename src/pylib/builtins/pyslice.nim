

type
  PySlice1* = ref object of RootObj  ## slice of 1 step
    start*, stop*: int
    
  PySlice* = ref object of PySlice1
    step*: int

func `==`*(self: PySlice, o: PySlice): bool =
  template eq(a): bool = self.a == o.a
  eq(start) and eq(stop) and eq(step)

template richcmp(op) =
  func op*(self: PySlice, o: PySlice): bool =
    template unpack(s): tuple = (s.start, s.stop, s.step)
    op unpack(self), unpack(o)

richcmp `<`
richcmp `<=`
# other cmp ops are handled by system's template

func slice*(start, stop: int): PySlice1 =
  PySlice1(start: start, stop: stop)

func slice*(start, stop: int, step: int): PySlice =
  PySlice(start: start, stop: stop, step: step)

func slice*(stop: int): PySlice1 = slice(0, stop)

converter toPySlice*(s: PySlice1): PySlice =
  result = PySlice(start: s.start, stop: s.stop, step: 1)

proc toNimSlice*(s: PySlice1): Slice[int] =
  assert result.a >= 0 and result.b >= 0
  result.b = s.stop - 1
  result.a = s.start

func repr*(self: PySlice): string =
  result = "slice(" & $self.start & ", "
  result.add $self.stop & ", "
  result.add $self.step & ')'


func getLongIndices(self: PySlice, length: int):
    tuple[start, stop, step: int] =
  let step = self.step
  let step_is_negative = step < 0
  
  var lower, upper: int
  if step_is_negative:
    lower = -1
    upper = length + lower
  else:
    lower = 0
    upper = length
  
  template cal(st) =
    var st = self.st
    if st < 0:
      st.inc length
    
      if st < lower:
        st = lower
    else:
      if st > upper:
        st = upper
  cal start
  cal stop
  result.start = start
  result.stop = stop
  result.step = step

func indices*(self: PySlice, length: int): (int, int, int) =
  if length < 0:
    raise newException(ValueError, "length should not be negative")
  getLongIndices(self, length)  


