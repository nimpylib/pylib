/*
Only ones used by this directory (pylib/impure/Python/*.c) are declared here
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <limits.h>
#include <assert.h>

int
PyOS_vsnprintf(char *str, size_t size, const char  *format, va_list va);
