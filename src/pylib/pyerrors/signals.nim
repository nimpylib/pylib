
import ../noneType

type
  StopIterationT*[T = NoneType] = object of CatchableError
    ## EXT. as `StopIteraton`'s `value` was not statically typed in Python, this must be
    ##  used for those whose `value` is not None
    value*: T  ## generator return value
  StopIteration* = StopIterationT[NoneType]
    ## .. note:: CPython's StopIteration is not generics, at least as of 3.13

  StopAsyncIteration* = object of CatchableError
  GeneratorExit* = object of CatchableError

func newStopIteration*(): ref StopIteration = newException(StopIteration, "")
func newStopIteration*[T](value: T): ref StopIterationT[T] =
  result = newException(StopIterationT[T], "")
  result.value = value

func `$`*(self: StopIteration): string = ""
func `$`*(self: StopIterationT): string = $self.value

func msg*(self: StopIteration): string = "StopIteration"
func msg*(self: StopIterationT): string = "StopIteration: " & $self.value
