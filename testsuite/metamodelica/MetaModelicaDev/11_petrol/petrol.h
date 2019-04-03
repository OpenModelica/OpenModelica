/* petrol.h */
#include <stdio.h>
#define P_OFFSET(FIELD,PTR) (&((PTR)->FIELD))
#define petrol_read() fgetc(stdin)
#define petrol_trunc(R) ((int)(R))
#define petrol_write(C) fputc(C,stdout)
