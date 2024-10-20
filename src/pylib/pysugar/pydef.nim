##[ python's def and async def

support:
  - param
  - param: type
  - param = defval
  - `*args`
  - -> restype
  - """doc-str""" or "doc-str"
  - nested def or async def
  
limits:
  - `*args` can only contain one type's arguments
  - can't combine type and defval i.e. `param: type = defval` is unsupported
  - for async def, only `-> Future[void]` can be omitted. Refer to std/asyncmacro for details
  - variables must be declared using `let`/`var`/`const` (this can be solved but is unnecessary)
  
unsupport:
  - generator (yield within def)  *TODO*
  - `**kws`
  - `*` and `/` in parameters-list
see codes in `runnableExamples` for more details
]##

#[def has AST structure like this:
  Command
    Ident !"def"
    Call
      Ident !"argument"
      Ident !"second_argument"
      ExprEqExpr
        Ident !"default_arg"
        FloatLit 0.0
    StmtList
      procedure body here
]#

import std/macros
import ./stmt/[pydef, tonim]
import ./parserWithCfg
export PySignatureSupportGenerics

macro define*(signature, body): untyped =
  ## almost the same as `def`, but is for `template` instead of `proc`
  ##
  ## XXX: nesting `define` is not supported. If wanting, use `template`.
  ## however, `def` in `define` is allowed.
  runnableExamples:
    define templ(a): a+1  # note template has no implicit `result` variable
    assert templ(3) == 4
  var parser = parserWithDefCfg()
  defAux(signature, body, parser=parser, deftype=ident"untyped", procType=nnkTemplateDef)

macro def*(signature, body): untyped =
  runnableExamples:
    def add(a,b): return a + b # use auto as argtype and restype
    def addi(a: int, b = 1) -> int: return add(a, b)
    assert addi(3) == 4
    def nested(a):
      def closure():
        return a
      return closure
    assert nested(3)() == 3
    def max(a, b, *args):
      "This is doc-str: a python-like `max`"
      def max2(a,b):
        if a>b: return a
        else: return b
      result = max2(a, b)
      for i in args:
        result = max2(result, i)
      return result
    assert max(1,4,2,5,0) == 5
    when PySignatureSupportGenerics:  # pysince 3.13
      def sub[T](a: T, b: T) -> T:
        return a - b
      assert sub(4, 5) == -1

      def f2[A, B](a: A, b: B) -> A:
        return a + A(b)
      assert int(2) == f2(1, 1.0)
  var parser = parserWithDefCfg()
  defImpl(signature, body, parser=parser)


macro async*(defsign, body): untyped =
  ## `async def ...`
  runnableExamples:
    import std/async
    async def af():
      discard "no restype mean Future[void]"
    async def afi() -> Future[int]:
      return 3
    when defined(js):
      await af()
      echo await afi()
    else:
      import std/asyncdispatch
      waitFor af()
      assert 3 == waitFor(afi())
  var parser = parserWithDefCfg()
  asyncImpl defsign, body, parser=parser

