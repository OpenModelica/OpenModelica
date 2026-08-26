#include "omc_simulation_settings.h"
#include "HashSetString.h"
#include "util/modelica.h"
#include "HashSetString_includes.h"
DLLDirection
modelica_metatype omc_HashSetString_emptyHashSetSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashSet = NULL;
modelica_metatype tmpMeta1;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta1 = mmc_mk_box3(0, boxvar_stringHashDjb2, boxvar_stringEq, boxvar_Util_id);
_hashSet = omc_BaseHashSet_emptyHashSetWork(threadData, _size, tmpMeta1);
_return: OMC_LABEL_UNUSED
return _hashSet;
}
modelica_metatype boxptr_HashSetString_emptyHashSetSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashSet = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashSet = omc_HashSetString_emptyHashSetSized(threadData, tmp1);
return _hashSet;
}
DLLDirection
modelica_metatype omc_HashSetString_emptyHashSet(threadData_t *threadData)
{
modelica_metatype _hashSet = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashSet = omc_HashSetString_emptyHashSetSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashSet;
}
