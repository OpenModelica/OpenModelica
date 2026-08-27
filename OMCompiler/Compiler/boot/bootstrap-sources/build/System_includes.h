#ifdef __cplusplus
extern "C" {
#endif
#include <stdlib.h>
#define architecture_numbits() (8*sizeof(void*))
void* StringAllocator_constructor(int sz)
{
if (sz < 0) {
MMC_THROW();
}
return mmc_alloc_scon(sz);
}
void om_stringAllocatorStringCopy(void *dest, char *source, int destOffset) {
if (*source) {
strcpy(MMC_STRINGDATA(dest)+destOffset, source);
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
#include "System.h"
#ifdef __cplusplus
}
#endif
