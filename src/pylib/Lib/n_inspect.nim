
import ../private/inspect_cleandoc


func cleandoc*(s: string): string{.inline.} =
  ## Cleans up a docstring by removing leading whitespace and trailing newlines.
  ##
  ## The first line of the docstring is also removed, as it is assumed to be
  ## the docstring's summary.
  ##
  ## The docstring is also trimmed of leading and trailing whitespace.
  ##
  `inspect.cleandoc` s

