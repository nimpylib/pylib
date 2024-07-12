.. warning:: A few of the format directives for `strftime`/`strptime` are not supported,
  and using them causes `AssertDefect`. They are listed in
  `nstrfptime.NotImplDirectives<time_impl/nstrpftime.html#NotImplDirectives>`_
.. hint:: Some directives (only for strftime) whose implementents are platform-depend
  in CPython are always supported here: '%V' '%G' '%g'