#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/HashSetExp.c"
#endif
#include "omc_simulation_settings.h"
#include "HashSetExp.h"
#include "util/modelica.h"
#include "HashSetExp_includes.h"
DLLExport
modelica_metatype omc_HashSetExp_emptyHashSetSized(threadData_t *threadData, modelica_integer _size)
{
modelica_metatype _hashSet = NULL;
modelica_metatype tmpMeta[1] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = mmc_mk_box3(0, boxvar_Expression_hashExpMod, boxvar_Expression_expEqual, boxvar_ExpressionDump_printExpStr);
_hashSet = omc_BaseHashSet_emptyHashSetWork(threadData, _size, tmpMeta[0]);
_return: OMC_LABEL_UNUSED
return _hashSet;
}
modelica_metatype boxptr_HashSetExp_emptyHashSetSized(threadData_t *threadData, modelica_metatype _size)
{
modelica_integer tmp1;
modelica_metatype _hashSet = NULL;
tmp1 = mmc_unbox_integer(_size);
_hashSet = omc_HashSetExp_emptyHashSetSized(threadData, tmp1);
return _hashSet;
}
DLLExport
modelica_metatype omc_HashSetExp_emptyHashSet(threadData_t *threadData)
{
modelica_metatype _hashSet = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_hashSet = omc_HashSetExp_emptyHashSetSized(threadData, ((modelica_integer) 2053));
_return: OMC_LABEL_UNUSED
return _hashSet;
}
