

from std/strutils import split, strip
from ../stringlib/meth import expandtabsImpl, join

const sys_maxsize = high int

{.push inline.}
func expandtabs(a: openArray[char], tabsize=8): string =
  expandtabsImpl(a, tabsize, a.len, items)

func lstripNSpaces(s: openArray[char]): int =
  ##[Remove leading spaces from a string.]##
  let slen = s.len
  while result < slen and s[result] == ' ':
    result.inc

func lstripSpaces(s: string): string = s.substr s.lstripNSpaces()
{.pop.}

func `inspect.cleandoc`*(doc: openArray[char]): string =
  ##[Clean up indentation from docstrings.

  Any whitespace that can be uniformly removed from the second line
  onwards is removed.

  .. note:: this is also used as `_PyCompile_CleanDoc` here. Nim itself will trace the fileno of the file being
   compiled. no need to keep the leading adn tailing blank lines like
   `Python/compile.c: _PyCompile_CleanDoc` does.
]##
  var lines = doc.expandtabs().split('\n')

  # Find minimum indentation of any non-blank lines after first line.
  var margin = sys_maxsize
  let hi = lines.high
  for i in 1..hi:
    let
      line = lines[i]
      le = line.len
      nLeading = line.lstripNSpaces()
      content = le - nLeading
    if content > 0:
      # let indent = le - content  # then in fact indent = nLeading
      margin = min(margin, nLeading)
  # Remove indentation.
  if lines.len > 0:
    lines[0] = lines[0].lstripSpaces()
  if margin < sys_maxsize:  # then there was some indentation
    for i in 1 .. hi:
      lines[i] = lines[i].substr margin
  # Remove any trailing or leading blank lines.
  var
    start = 0
    stop  = hi
  while stop  > 0  and lines[^stop].len == 0:
    dec stop
  while start < hi and lines[start].len == 0:
    inc start
  ## a inline and faster version of:
  ##  '\n'.join lines.toOpenArray(start, stop)
  result = lines[start]
  inc start
  for i in start..stop:
    result.add '\n'
    result.add lines[i]

when isMainModule:
    # from test_inspecty.py: test_cleandoc
    const
      cleandoc_testdata = [
        # first line should have different margin
        (" An\n  indented\n   docstring.", "An\nindented\n docstring."),
        # trailing whitespace are not removed.
        (" An \n   \n  indented \n   docstring. ",
         "An \n \nindented \n docstring. "),
        #[ XXX: TODO: std/strutils.split doesn't support NUL very well,
          just gives `["doc\0string", "", "  second\0line", "  third\0line\0"]`
        # NUL is not termination.
        ("doc\0string\n\n  second\0line\n  third\0line\0",
         "doc\0string\n\nsecond\0line\nthird\0line\0"),
         ]#
        # first line is lstrip()-ped. other lines are kept when no margin.[w:
        ("   ", ""),
        # compiler.cleandoc() doesn"t strip leading/trailing newlines
        # to keep maximum backward compatibility.
        # inspect.cleandoc() removes them.
        ("\n\n\n  first paragraph\n\n   second paragraph\n\n",
         "\n\n\nfirst paragraph\n\n second paragraph\n\n"),
        ("   \n \n  \n   ", "\n \n  \n   "),
      ]

    import std/enumerate
    block:
        for i, (input, expected) in enumerate(cleandoc_testdata):
            # only inspect.cleandoc() strip \n
            #expected = expected.strip("\n")
            if (`inspect.cleandoc`(input) == expected.strip(chars={'\n'})): continue
            echo repr `inspect.cleandoc`(input)
            echo repr expected.strip(chars={'\n'})
