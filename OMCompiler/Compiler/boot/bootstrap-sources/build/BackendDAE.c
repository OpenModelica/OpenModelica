#include "omc_simulation_settings.h"
#include "BackendDAE.h"
#include "util/modelica.h"
#include "BackendDAE_includes.h"
DLLDirection
modelica_integer omc_BackendDAE_getSimIteratorSize(threadData_t *threadData, modelica_metatype _iters)
{
modelica_integer _size;
modelica_integer _local_size;
modelica_metatype tmpMeta1;
modelica_integer tmp2 = 0;
modelica_metatype tmpMeta7;
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
MemPoolState omc_pool_state = omc_util_get_pool_state();
#endif
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_size = ((modelica_integer) 1);
{
modelica_metatype _iter;
for (tmpMeta1 = _iters; !listEmpty(tmpMeta1); tmpMeta1=MMC_CDR(tmpMeta1))
{
_iter = MMC_CAR(tmpMeta1);
{
modelica_metatype tmp5_1;
tmp5_1 = _iter;
{
volatile mmc_switch_type tmp5;
int tmp6;
tmp5 = 0;
for (; tmp5 < 2; tmp5++) {
switch (MMC_SWITCH_CAST(tmp5)) {
case 0: {
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,0,7) == 0) goto tmp4_end;
tmp2 = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iter), 7))));
goto tmp4_done;
}
case 1: {
if (mmc__uniontype__metarecord__typedef__equal(tmp5_1,1,4) == 0) goto tmp4_end;
tmp2 = mmc_unbox_integer((MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(_iter), 4))));
goto tmp4_done;
}
}
goto tmp4_end;
tmp4_end: ;
}
goto goto_3;
goto_3:;
MMC_THROW_INTERNAL();
goto tmp4_done;
tmp4_done:;
}
}
_local_size = tmp2;
_size = (_size) * (_local_size);
}
}
_return: OMC_LABEL_UNUSED
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
omc_util_restore_pool_state(omc_pool_state);
#endif
return _size;
}
modelica_metatype boxptr_BackendDAE_getSimIteratorSize(threadData_t *threadData, modelica_metatype _iters)
{
modelica_integer _size;
modelica_metatype out_size;
_size = omc_BackendDAE_getSimIteratorSize(threadData, _iters);
out_size = mmc_mk_icon(_size);
return out_size;
}
