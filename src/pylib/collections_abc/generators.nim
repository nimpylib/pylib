
import ../noneType
import ./iters
import ./private/templ
import ../pyerrors/signals

type
  Generator*[YieldType, SendType = NoneType, ReturnType = NoneType] =
      concept self of Iterator[YieldType]
    ## `type( (def _(): yield)() )`
    try: self.send(SendType) is YieldType
    except StopIteration[ReturnType]: discard
    self.throw(CatchableError)


proc close*(self: Generator) =
  closeImpl("generator"):
    self.throw(GeneratorExit)

template iter*[T; S; R](self: Generator[T, S, R]): Iterator[T] = self
proc next*[T; R](self: Generator[T, NoneType, R]): T{.inline.} = self.send(None)

