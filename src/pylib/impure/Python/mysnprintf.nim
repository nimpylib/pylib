
{.compile: "./mysnprintf.c".}

proc PyOS_snprintf*(str: cstring, size: csize_t|int): cint{.discardable, importc, cdecl, varargs.}
