.. warning:: In current implementation,
  whitespace in format string means itself AS-IS, unlike C or Python,
  where any whitespace means a serial of any whitespaces. If really
  wanting the behavior of C's, consider use `std/strscan`.

.. warning:: Current `strptime`
  is just locale-unaware, when it comes to 
  "the locale's format", like `"%x"`, it always uses the format of
  `"C" locale`, no matter what the locale is. a.k.a. Changing
  locale via C's api in `<locale.h>` doesn't affect this function.
