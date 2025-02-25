##[

## Coroutine

ref [pep of `Coroutines with async and await syntax`](https://peps.python.org/pep-0492/),
`Future-like object` is just an alias of `Awaitable`_

```python
V = 1
async def f():
    return V

c: Coroutine[None, None, int] = f()

try: c.send(None)
except StopIteraion as s: assert V == s.value

try: c.send(None)
except RuntimeError as e: assert str(e) == "cannot reuse already awaited coroutine"

# Also: V == await f()
```


[pep for Asynchronous Generators](https://peps.python.org/pep-0525/)

## AsyncGenerator

```python
V = 1
async def f(): yield V
ag = f()

ag_asend_obj = ag.asend(None)  #  or `anext(ag)`
try: ag_asend_obj.send(None)
except StopIteration as s: assert V == s.value


ag_asend_obj = ag.asend(None)  #  or `anext(ag, defval)` if wanting
# the next `send` raises `StopIteration` and its value to be `defval`

try: ag_asend_obj.send(None)
except StopAsyncIteration: pass   # iteration end


```

for `ag_asend_obj`, ref [link of PyAsyncGenASend](
https://peps.python.org/pep-0525/#pyasyncgenasend-and-pyasyncgenathrow):

> `PyAsyncGenASend` is a coroutine-like object...

> `PyAsyncGenAThrow` is very similar to `PyAsyncGenASend`.
The only difference is that `PyAsyncGenAThrow.send()`, when called first time,
throws an exception into the parent `agen` object
(instead of pushing a value into it.)

]##


import std/asyncfutures
import std/asyncmacro

import ../pyerrors/signals
import ../noneType
import ./private/templ

type
  Awaitable*[T] = concept self
    T is await self
  Coroutine*[Yield, Send, Return] =
      concept self of Awaitable[Return]
    ## `type( (async def _(): return Return() )() )`
    ## in details: `Coroutine[None, None, Return]`
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
    self.athrow(CatchableError) is Awaitable[void]

proc anext*[T](self: AsyncGenerator[T]): Awaitable[T]{.inline.} =
  ## this shall be an `async def`
  self.asend(None)

type anextawaitableobject[T] = object
  wrapped: AsyncGenerator[T]
  default_value: T

proc await*[T](self: anextawaitableobject[T]): T = 
  try:
    result = await self.wrapped.asend(None)
  except StopAsyncIteration:
    #raise newStopIteration(default)
    result = default

proc anext*[T](self: AsyncGenerator[T], default: T): Awaitable[T]{.inline.} =
  anextawaitableobject(wrapped: self, default: default)

proc aclose*(self: AsyncGenerator){.async.} =
  closeImpl("asunchronous generator"):
    await self.athrow(GeneratorExit)
