#ifdef __cplusplus
extern "C" {
#endif
#include "openmodelica.h"       // Defines OPENMODELICA_H_ for libraries to test if called from OpenModelica.
#include "ModelicaUtilities.h"  // Make Modelica C util functions available for external includes.
#include <stdlib.h>
#define architecture_numbits() (8*sizeof(void*))
void* StringAllocator_constructor(int sz)
{
void *res;
if (sz < 0) {
MMC_THROW();
}
res = mmc_alloc_scon(sz);
if (sz > 0) {
((char*)MMC_STRINGDATA(res))[sz] = '\0';
}
return res;
}
void om_stringAllocatorStringCopy(void *dest, char *source, int destOffset) {
size_t n = strlen(source);
if (n > 0) {
memcpy(MMC_STRINGDATA(dest)+destOffset, source, n);
}
}
void* om_stringAllocatorResult(void *sa) {
return sa;
}
#include <stdio.h>
void SystemImpl__fflush(void)
{
fflush(NULL);
}
#include "Error.h"
#include "System.h"
#ifdef __cplusplus
}
#endif
