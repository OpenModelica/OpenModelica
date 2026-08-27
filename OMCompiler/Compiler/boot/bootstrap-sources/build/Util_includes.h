#ifdef __cplusplus
extern "C" {
#endif
static inline int referenceCompareExt(void *ref1, void *ref2)
{
return (ref1 < ref2) ? -1 : (ref1 > ref2);
}
#include "List.h"
#include "Print.h"
#include "System.h"
#include "Util.h"
#ifdef __cplusplus
}
#endif
