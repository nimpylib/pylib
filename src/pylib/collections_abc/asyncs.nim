
import std/asyncdispatch
import ../pyerrors/signals
#import ../builtins/iter_next
import ./private/templ

type
  Awaitable*[T] = concept self
    T is await self
  Coroutine*[Yield, Send, Return] = concept self of Awaitable[Return]
    ## `type( (async def _(): pass)() )`
    self.send(Send) is Yield
    self.throw(CatchableError)


proc close*(self: Coroutine) =
  closeImpl("coroutinue"):
    self.throw(GeneratorExit)

#[ TODO: support after PyTrceback is impl
import ../noneType
when (PyMajor, PyMinor) >= (3,12):
  {.pragma deprThrowVariant, warning:
    "The signature (type[, value[, traceback]]) is deprecated and " &
    " may be removed in a future version of Python.".}
else:
  {.pragma deprThrowVariant.}

proc throw*[E](self: Coroutine,
    `type`: typedesc[E], val: E; tb: PyTraceback | NoneType = None){.deprThrowVariant.} =
  when tb is_not NoneType:
    val = val.with_traceback(tb)
  raise val

proc throw*[E](self: Coroutine,
    `type`: E, val: NoneType; tb: PyTraceback | NoneType = None){.deprThrowVariant.} =
]#

type
  AsyncIterable*[T] = concept self
    aiter(self) is AsyncIterator[T]
  AsyncIterator*[T] = concept self of AsyncIterable[T]
    anext(self) is Awaitable[T]
  
  AsyncGenerator*[Yield; Send = NoneType] = concept self of AsyncIterator[Yield]
    ##[
      `type( (async _(): yield)() )`
      ABC for such a function which returns an asynchronous generator iterator.
      It looks like a coroutine function defined with async def except
      that it contains yield expressions for producing a series of
      values usable in an async for loop.
    ]##
    self.asend(Send) is Awaitable[Yield]
    self.athrow(CatchableError) is Awaitable #[void]#

proc anext*[T](self: AsyncGenerator[T]): Awaitable[T]{.inline.} =
  ## this shall be an `async def`
  self.asend(None)

proc aclose*(self: AsyncGenerator){.async.} =
  closeImpl("asunchronous generator"):
    await self.athrow(GeneratorExit)
