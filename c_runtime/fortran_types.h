/* From f2c.h for compatibility - you may not include f2c.h in C++ headers or
 * or you break the templates. */

#ifndef FORTRAN_TYPES_INCLUDE
#define FORTRAN_TYPES_INCLUDE

#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int fortran_integer;
typedef unsigned int fortran_uinteger;
#else
typedef long int fortran_integer;
typedef unsigned long int fortran_uinteger;
#endif

#endif
