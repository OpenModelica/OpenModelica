#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "Global.c"
#endif
#include "omc_simulation_settings.h"
#include "Global.h"
#include "util/modelica.h"
#include "Global_includes.h"
DLLExport
void omc_Global_initialize(threadData_t *threadData)
{
modelica_metatype tmpMeta1;
modelica_metatype tmpMeta2;
modelica_metatype tmpMeta3;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
setGlobalRoot(((modelica_integer) 0), mmc_mk_none());
setGlobalRoot(((modelica_integer) 19), mmc_mk_none());
setGlobalRoot(((modelica_integer) 20), mmc_mk_none());
setGlobalRoot(((modelica_integer) 22), mmc_mk_none());
setGlobalRoot(((modelica_integer) 23), mmc_mk_none());
setGlobalRoot(((modelica_integer) 26), mmc_mk_none());
tmpMeta1 = MMC_REFSTRUCTLIT(mmc_nil);
setGlobalRoot(((modelica_integer) 10), tmpMeta1);
tmpMeta2 = MMC_REFSTRUCTLIT(mmc_nil);
setGlobalRoot(((modelica_integer) 11), tmpMeta2);
tmpMeta3 = MMC_REFSTRUCTLIT(mmc_nil);
setGlobalRoot(((modelica_integer) 12), tmpMeta3);
_return: OMC_LABEL_UNUSED
return;
}
