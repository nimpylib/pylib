
import ./strimpl
import ../translateEscape

func u*(s: static[string]{lit}): PyStr =
  const ns = translateEscape s
  str(ns)

func u*(a: char{lit}): PyStr = str(a)
