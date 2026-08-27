#ifdef OMC_BASE_FILE
#define OMC_FILE OMC_BASE_FILE
#else
#define OMC_FILE "/home/mahge/dev/OpenModelica/OMCompiler/Compiler/boot/build/tmp/InstStateMachineUtil.c"
#endif
#include "omc_simulation_settings.h"
#include "InstStateMachineUtil.h"
#include "util/modelica.h"
#include "InstStateMachineUtil_includes.h"
DLLExport
modelica_metatype omc_InstStateMachineUtil_wrapSMCompsInFlatSMs(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inDae1, modelica_metatype _inDae2, modelica_integer _smNodeToFlatSMGroup, modelica_metatype _smInitialCrefs, modelica_metatype *out_outDae2)
{
modelica_metatype _outDae1 = NULL;
modelica_metatype _outDae2 = NULL;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_outDae1 = _inDae1;
_outDae2 = _inDae2;
_return: OMC_LABEL_UNUSED
if (out_outDae2) { *out_outDae2 = _outDae2; }
return _outDae1;
}
modelica_metatype boxptr_InstStateMachineUtil_wrapSMCompsInFlatSMs(threadData_t *threadData, modelica_metatype _inIH, modelica_metatype _inDae1, modelica_metatype _inDae2, modelica_metatype _smNodeToFlatSMGroup, modelica_metatype _smInitialCrefs, modelica_metatype *out_outDae2)
{
modelica_integer tmp1;
modelica_metatype _outDae1 = NULL;
tmp1 = mmc_unbox_integer(_smNodeToFlatSMGroup);
_outDae1 = omc_InstStateMachineUtil_wrapSMCompsInFlatSMs(threadData, _inIH, _inDae1, _inDae2, tmp1, _smInitialCrefs, out_outDae2);
return _outDae1;
}
DLLExport
modelica_integer omc_InstStateMachineUtil_createSMNodeToFlatSMGroupTable(threadData_t *threadData, modelica_metatype _inDae)
{
modelica_integer _smNodeToFlatSMGroup;
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
_smNodeToFlatSMGroup = ((modelica_integer) 0);
_return: OMC_LABEL_UNUSED
return _smNodeToFlatSMGroup;
}
modelica_metatype boxptr_InstStateMachineUtil_createSMNodeToFlatSMGroupTable(threadData_t *threadData, modelica_metatype _inDae)
{
modelica_integer _smNodeToFlatSMGroup;
modelica_metatype out_smNodeToFlatSMGroup;
_smNodeToFlatSMGroup = omc_InstStateMachineUtil_createSMNodeToFlatSMGroupTable(threadData, _inDae);
out_smNodeToFlatSMGroup = mmc_mk_icon(_smNodeToFlatSMGroup);
return out_smNodeToFlatSMGroup;
}
DLLExport
modelica_metatype omc_InstStateMachineUtil_getSMStatesInContext(threadData_t *threadData, modelica_metatype _eqns, modelica_metatype _inPrefix, modelica_metatype *out_initialStates)
{
modelica_metatype _states = NULL;
modelica_metatype _initialStates = NULL;
modelica_metatype tmpMeta[2] __attribute__((unused)) = {0};
MMC_SO();
_tailrecursive: OMC_LABEL_UNUSED
tmpMeta[0] = MMC_REFSTRUCTLIT(mmc_nil);
_states = tmpMeta[0];
tmpMeta[1] = MMC_REFSTRUCTLIT(mmc_nil);
_initialStates = tmpMeta[1];
_return: OMC_LABEL_UNUSED
if (out_initialStates) { *out_initialStates = _initialStates; }
return _states;
}
