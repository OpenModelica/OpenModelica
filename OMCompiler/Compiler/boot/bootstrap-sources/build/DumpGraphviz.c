#include "omc_simulation_settings.h"
#include "DumpGraphviz.h"
#define _OMC_LIT0_data "DumpGraphviz.dump"
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT0,17,_OMC_LIT0_data);
#define _OMC_LIT0 MMC_REFSTRINGLIT(_OMC_LIT_STRUCT0)
#include "util/modelica.h"
#include "DumpGraphviz_includes.h"
DLLDirection
void omc_DumpGraphviz_dump(threadData_t *threadData, modelica_metatype _p)
{
static int tmp1 = 0;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
{
if(!0)
{
{
FILE_INFO info = {"DumpGraphviz.mo",41,3,41,35,0};
omc_assert(threadData, info, MMC_STRINGDATA(_OMC_LIT0));
}
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return;
}
