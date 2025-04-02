
import ./util

when not weirdTarget:
  when not defined(pylibSysNoStdio):
    # CPython's stdio is init-ed by create_stdio in Python/pylifecycle.c
    import ../io
    export io.read, io.readline, io.write, io.fileno, io.isatty, io.flush

    template wrap(ioe): untyped =
      var ioe* = newNoEncTextIO(
        name = '<' & astToStr(ioe) & '>',
        file = system.ioe, newline=DefNewLine)
    # XXX: NIM-BUG: under Windows, system.stdin.readChar for non-ASCII is buggy,
    # returns a random char for one unicode.
    wrap stdin
    wrap stdout
    wrap stderr
    stdin.mode = "r"
    stdout.mode = "w"
    stderr.mode = "w"
    let
      dunder_stdin* = stdin   ## __stdin__
      dunder_stdout* = stdout ## __stdout__
      dunder_stderr* = stderr ## __stderr__
