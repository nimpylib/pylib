
#include <stdlib.h>

void ACQUIRE_DTOA_LOCK(int);
void FREE_DTOA_LOCK(int);

int dtoa_get_threadno(void);

// avoid MinGW complaining conflict with strtod of <stdlib.h>
#define strtod nimpylib_dtoa_strtod
#include "./dtoa.c"
#undef strtod
